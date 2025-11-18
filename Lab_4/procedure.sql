------------------------------------------------------------------------
-- 1. Хранимые процедуры
------------------------------------------------------------------------

-- а) Список больных, проходящих лечение в данный момент:
--	  отделение, палата, ФИО пациента

drop procedure if exists list_of_patients;
create procedure list_of_patients as
begin
	select 
		hd.name as hospital_department, 
		w.number as ward, 
		p.full_name as name_patient
	from 
		patient p
		join patient_card pc on p.id = pc.id_patient
		join ward w on p.id_ward = w.id
		join hospital_department hd on w.id_hospital_department = hd.id
	where
		pc.date_of_discharge is null
	order by
		hd.name,
		w.number,
		p.full_name;
end

exec list_of_patients; -- Вызов

-- b) С параметром. Номер отделения -> свободные палаты
--	  номер палаты, тип палаты(м/ж), кол-во свободных мест

drop procedure if exists free_ward_dep;
create procedure free_ward_dep(@number_hospital_department SMALLINT)
as
begin
	select
		w.number, w.m_or_w, 
		--w.number_of_beds - count(p.id_ward) as free_beds
		-- При составлении таблицы я не заметил, что пациенты(даже если они уже выписаны)
		-- приписаны к палате(я заметил это только когда составлял триггер)
		-- Здесь наверно лучше использовать:
		w.number_of_beds - sum(case when pc.date_of_discharge is null then 1 else 0 end) as free_beds
	from 
		hospital_department hd
		join ward w on hd.id = w.id_hospital_department
		left join patient p on w.id = p.id_ward
		left join patient_card pc on p.id = pc.id_patient
	where 
	    hd.id = @number_hospital_department
	group by
		w.number, w.m_or_w, w.number_of_beds 
	having 
		w.number_of_beds - count(p.id_ward) > 0
	
end

exec free_ward_dep 1; -- Вызов


-- c) С параметром. Название отделения -> средняя загруженность палат в отделении
drop procedure if exists avg_ward_workload;
create procedure avg_ward_workload(@name_hospital_department NVARCHAR(255))
as 
begin
    declare @id_hd INT = (select id from hospital_department where name = @name_hospital_department);
    
    select 
        AVG(cast(patient_count as FLOAT) / number_of_beds) as avg_workload
    from (
        select 
            w.id,
            w.number_of_beds,
            COUNT(p.id) as patient_count
        from ward w
        left join patient p on w.id = p.id_ward
        where w.id_hospital_department = @id_hd
        group by w.id, w.number_of_beds
    ) as ward_stats;
end;

exec avg_ward_workload N'Кардиологическое отделение'; -- Вызов


-- d) Вложенная процедура "с)" нужно вывести палаты где < средней загруженности
drop procedure if exists wards_below_average_workload;
create procedure wards_below_average_workload(@name_hospital_department NVARCHAR(255))
as
begin
    declare @id_hd INT;
    declare @avg_workload DECIMAL(5,4);
    
    select @id_hd = id 
    from hospital_department 
    where name = @name_hospital_department;
    
    create table #temp_workload (avg_value DECIMAL(5,4));
    
    insert into #temp_workload (avg_value)
    exec avg_ward_workload @name_hospital_department;

    select @avg_workload = avg_value from #temp_workload;

    select 
        w.number as ward_number,
        w.m_or_w,
        w.number_of_beds,
        COUNT(p.id) as current_patients,
        CAST(COUNT(p.id) AS FLOAT) / w.number_of_beds as current_workload,
        @avg_workload as average_department_workload
    from 
    	ward w
    	left join patient p ON w.id = p.id_ward
    where 
    	w.id_hospital_department = @id_hd
    group by 
    	w.id, w.number, w.m_or_w, w.number_of_beds
    having 
    	cast(COUNT(p.id) AS FLOAT) / w.number_of_beds < @avg_workload
    order by 
    	w.number;
    
    drop table #temp_workload;
end;

exec wards_below_average_workload N'Кардиологическое отделение'; -- Вызов
