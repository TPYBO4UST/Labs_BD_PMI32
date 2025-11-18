------------------------------------------------------------------------
-- 3. Триггеры
------------------------------------------------------------------------

------------------------------------------------------------------------
-- а) Проверка на свободные места(при добавлении пациента в палату)
drop trigger if exists check_free_ward;
go
create trigger check_free_ward
on patient
after insert 
as
begin
	set nocount on
	
	if exists (
		select
			w.id
		from
			ward w
			join inserted i on w.id = i.id_ward
		where
			w.number_of_beds < (select count(*) from patient p where p.id_ward = w.id)
		
	)
	begin
		raiserror(N'Превышена вместимость палаты!', 16, 1)
		rollback transaction
		return
	end
	
end;

-- проверка 

-- Загруженная палата
select 
    w.id,
    w.number,
    w.number_of_beds,
    COUNT(p.id) as current_patients
from
	ward w
	join patient p ON w.id = p.id_ward
group by 
	w.id, w.number, w.number_of_beds
having 
	COUNT(p.id) >= w.number_of_beds;
-- Загруженная палата 101 (ward.id = 1)

-- проверка
INSERT INTO patient (id_ward, full_name, passport, medical_policy, number_phone, address, date_of_birth, doctor_id)
VALUES (1, N'Тестовый Пациент', '4510991119', '9919191919', '+79160304000', N'ул. Тестовая, 1', '1990-01-01', 1);
------------------------------------------------------------------------


------------------------------------------------------------------------
-- b)  Последующий триггер на операцию выписки пациентов: изменение в соответствующих палатах кол-ва свободных мест

drop trigger if exists track_patient_discharge;
go
create trigger track_patient_discharge
on patient_card
after update
as
begin
	set nocount on
	
	-- Смотрим, произошол ли update
	if exists (
		select 1
		from 
			inserted i
			join deleted d on i.id_patient = d.id_patient
			where i.date_of_discharge is not null
				and d.date_of_discharge is null
	)
	begin
		PRINT N'УРА! ВЫПИСКА ПАЦИЕНТА :)'
		
		-- Выводим людей, которых выписываем
		select 
            p.id as patient_id,
            p.full_name,
            w.id as ward_id,
            w.number as ward_number,
            w.m_or_w as ward_type,
            w.number_of_beds as total_beds,
            (SELECT COUNT(*) FROM patient p2 WHERE p2.id_ward = w.id) as current_patients,
            w.number_of_beds - (SELECT COUNT(*) FROM patient p2 WHERE p2.id_ward = w.id) as free_beds_after
        from 
        	inserted i 
			join deleted d on i.id_patient = d.id_patient
			join patient p ON i.id_patient = p.id
        	join ward w ON p.id_ward = w.id
			where i.date_of_discharge is not null
				and d.date_of_discharge is null
		
		-- убираем привзяку к палате у людей, которых мы выписали
		update patient
		set id_ward = NULL
		where id in (
			select i.id_patient
			from inserted i 
			join deleted d on i.id_patient = d.id_patient
			where i.date_of_discharge is not null
				and d.date_of_discharge is null
		)
	end
	
end;




------------ Тест -----------
-- смотрим на выписанных(Например козлов id = 11 палата 402)
SELECT 
    p.id,
    p.full_name,
    w.number as ward_number,
    pc.date_of_receipt,
    pc.date_of_discharge
from 
	patient p
	join patient_card pc on p.id = pc.id_patient
	join ward w on p.id_ward = w.id
where 
	pc.date_of_discharge is null;

-- выписываем Козлова
update patient_card 
set date_of_discharge = GETDATE()
where id_patient = 11 and date_of_discharge is null;

-- Смотрим по палатам(теперь в палате 402 нет пациентов)
select 
    w.number as ward_number,
    w.number_of_beds as total_beds,
    COUNT(p.id) as current_patients,
    w.number_of_beds - COUNT(p.id) as free_beds
from 
	ward w
	left join patient p ON w.id = p.id_ward
	left join patient_card pc ON p.id = pc.id_patient
where pc.date_of_discharge IS NULL OR pc.date_of_discharge is not null
group by w.number, w.number_of_beds
order by w.number;


-- с) Триггер на удаление палат
-- Если в палате человек - удалять нельзя
-- Заменить id удаленной палаты на 99999999

-- При постоении БД я подумал что нам хватит для номера палат и 
-- smallint, поэтому буду использовать 9999

-- Создаем фиктивную палату с номером 9999
insert into ward (id_hospital_department, number, number_of_beds, m_or_w, key_diagnosis)
values (1, 9999, 100, 'M', 'Z53');

drop trigger if exists instead_of_delete_ward;
go
create trigger instead_of_delete_ward
on ward
instead of delete
as
begin
	set nocount on
	declare @ward_id SMALLINT
	declare @ward_number SMALLINT
	declare @patient_count INT
	declare @dummy_ward_id SMALLINT 
	
	select @dummy_ward_id = id 
    from ward 
    where number = 9999;
	
	 declare @results table (
        ward_id SMALLINT,
        ward_number SMALLINT,
        action_type NVARCHAR(255),
        message NVARCHAR(255)
    );

	
	declare ward_cursor cursor for
	select 
		d.id,
		d.number,
		(SELECT COUNT(*) FROM patient p WHERE p.id_ward = d.id) as patient_count
     from deleted d
	
	open ward_cursor
    fetch next from ward_cursor into @ward_id, @ward_number, @patient_count
    
    while @@FETCH_STATUS = 0
    begin
        if @patient_count > 0
        begin
            -- Палата с пациентами - не удаляем
            insert into @results values (
                @ward_id, 
                @ward_number, 
                'BLOCKED', 
                N'В палате ' + CAST(@ward_number AS NVARCHAR) + N' находится ' + 
                cast(@patient_count as NVARCHAR) + N' пациентов'
            )
        end
        
        else
        begin
            -- Обновляем связи в patient (если остались без пациентов)
            UPDATE patient 
            SET id_ward = @dummy_ward_id 
            WHERE id_ward = @ward_id;
            
            -- 3. Удаляем палату
            delete from ward 
            where id = @ward_id;
            
            insert into @results values (
                @ward_id, 
                @ward_number, 
                'DELETED', 
                N'Палата успешно удалена'
            )
        end

        fetch next from ward_cursor into @ward_id, @ward_number, @patient_count
    end

    close ward_cursor;
    deallocate ward_cursor;

    -- Выводим итоговый отчет
    PRINT N'=== ОТЧЕТ ПО УДАЛЕНИЮ ПАЛАТ ===';
    select 
        ward_id as 'ID палаты',
        ward_number as 'Номер палаты', 
        action_type as 'Действие',
        message as 'Результат'
    from @results
    order by action_type, ward_number;
end


select 
    w.id,
    w.number,
    w.m_or_w,
    COUNT(p.id) as patient_count
from ward w
left join patient p on w.id = p.id_ward
group by w.id, w.number, w.m_or_w
order by w.number;

delete from ward 
where number in (102, 104);  -- Пример
