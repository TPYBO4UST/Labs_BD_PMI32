------------------------------------------------------------------------
-- 2. Пользовательские функции
------------------------------------------------------------------------

-- a) Невыписанные пациенты
drop function if exists current_patient_count;
go
create function current_patient_count()
returns int
as
begin
	declare @patient_count int;
	
	select 
		@patient_count = count(*)
	from patient p 
	join patient_card pc on p.id = pc.id_patient
	where pc.date_of_discharge is null;
	
	return @patient_count;
end;

select dbo.current_patient_count();

-- b) Inline-функция, возвращающая список палат со свободными местами: 
-- отделение, палата, тип, кол-во свободных мест

drop function if exists wards_free_beds;
go
create function wards_free_beds()
returns table
as
return (
	select 
		hd.name as department_name,
		w.number as number_ward,
		w.m_or_w AS ward_type,
		w.number_of_beds - COUNT(p.id) AS free_beds
	from
		hospital_department hd
		join ward w on hd.id = w.id_hospital_department
		left join patient p on w.id = p.id_ward
	group by
		hd.name, 
        w.number, 
        w.m_or_w, 
        w.number_of_beds
    having 
    	w.number_of_beds - COUNT(p.id) > 0
);

select *
from 
	dbo.wards_free_beds();


-- c) Multi-statement-функция, выдающая список  диагнозов и кол-во пролеченных больных с этим диагнозом в виде:
-- Диагноз   |     общее число больных   |   м   |   ж   |   от 0 до 40 лет   |   после 40

drop function if exists diagnosis_statistics;
go


create function diagnosis_statistics()
returns @statistics table (
	diagnosis_title nvarchar(255),
	total_patients int,
	male_count int,
    female_count int,
    age_0_40_count int,
    age_40_plus_count int
)
as
begin
	declare @patient_data table (
        patient_id INT,
        diagnosis_title NVARCHAR(255),
        is_male BIT,
        age_group INT -- 1: 0-40, 2: 40+
    );

	insert into @patient_data(patient_id, diagnosis_title, is_male, age_group)
	select
		p.id,
		d.title,
		case when w.m_or_w = 'M' then 1 else 0 end,
		case when DATEDIFF(year, p.date_of_birth, GETDATE()) <= 40 then 1 else 2 end
	from
		patient p
		join patient_admission pa on p.id = pa.id_patient
		join ward w on p.id_ward = w.id
		join diagnosis d on pa.key_diagnosis = d.[code-mkb10]
	
	-- table to return
	insert into @statistics (
        diagnosis_title, 
        total_patients, 
        male_count, 
        female_count, 
        age_0_40_count, 
        age_40_plus_count
    )
    select 
    	diagnosis_title,
    	count(DISTINCT patient_id) AS total_patients,
        sum(case when is_male = 1 then 1 else 0 end) as male,
        sum(case when is_male = 0 then 1 else 0 end) as female,
        sum(case when age_group = 1 then 1 else 0 end) as age_0_40_count,
        sum(case when age_group = 2 then 1 else 0 end) as age_40_plus_count
    from
    	@patient_data
	group by diagnosis_title
	
	return
end;

SELECT * FROM dbo.diagnosis_statistics();
