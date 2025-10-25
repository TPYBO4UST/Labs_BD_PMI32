-------------------------------------------------------------------------------
-- 3. Представления
-------------------------------------------------------------------------------


	-- 3.1 Обернуть в представление
-- Создаем представелие(Доктор - пациент)
drop view if exists doctors_patients_view;
create view doctors_patients_view as
select 
    d.full_name as doctor_name,
    d.specialization,
    p.full_name as patient_name,
    p.date_of_birth
from 
	doctor d
left join 
	patient p on d.id = p.doctor_id;

select * from doctors_patients_view;


-- Представление(Такими заболеваниями пока не болели)
drop view if exists unused_diagnoses_view;

create view unused_diagnoses_view as
select 
    d.title as diagnosis_name,
    d.[code-mkb10] as code
from diagnosis d
where not exists (
    select 1
    from patient_admission pa
    where pa.key_diagnosis = d.[code-mkb10]
);
-- вызов представления
select * from unused_diagnoses_view;


	-- 3.2 CTE
-- врачи и количество их пациентов
with doctor_patient_count as (
    select 
        d.full_name as doctor_name,
        d.specialization,
        count(p.id) as patient_count
    from 
    	doctor d
    	left join patient p on d.id = p.doctor_id
    group by 
    	d.full_name, d.specialization
)
select 
    doctor_name,
    specialization,
    patient_count
from 
	doctor_patient_count
order by 
	patient_count desc;

	
-- Подсчет пациентов по отделениям
with department_patient_count as (
    select 
        hd.name as department_name,
        count(p.id) as patient_count
    from 
    	hospital_department hd
    	left join ward w on hd.id = w.id_hospital_department
    	left join patient p on w.id = p.id_ward
    group by 
    	hd.name
)
select 
    department_name,
    patient_count
from 
	department_patient_count
order by 
	patient_count desc;


-------------------------------------------------------------------------------
-- 4 Функции Ранжирования
-------------------------------------------------------------------------------


-- Рейтинг врачей по количеству пациентам
select 
    full_name as doctor_name,
    specialization,
    (select count(*) from patient where doctor_id = doctor.id) as patient_count,
    rank() over (order by (select count(*) from patient where doctor_id = doctor.id) desc) as rank_position
from doctor
order by rank_position;


-- Рейтинг пациентов по возрасту в каждом отделении
select 
    full_name as patient_name,
    datediff(year, date_of_birth, getdate()) as age,
    row_number() over (order by datediff(year, date_of_birth, getdate()) desc) as age_rank
from patient
order by age_rank;

-- row_number по специальности врачей
select 
    full_name as doctor_name,
    specialization,
    row_number() over (partition by specialization order by full_name) as number_in_specialization
from 
	doctor
order by 
	specialization, number_in_specialization;


-------------------------------------------------------------------------------
-- 5 Объдинение, пересечение, разность
-------------------------------------------------------------------------------


-- Объединение врачей и пациентов в одну таблицу
-- Объединение 
select full_name, N'Врач' as role from doctor
union all
select full_name, N'Пациент' as role from patient
order by role, full_name;


-- Врачи без пациентов
-- except - разность 
select full_name from doctor
except
select distinct d.full_name 
from doctor d 
join patient p on d.id = p.doctor_id;


-- Коды диагнозов которые есть в палатах и поступлениях 
-- intersect - пересечение
select key_diagnosis from ward
intersect 
select key_diagnosis from patient_admission

-------------------------------------------------------------------------------
-- 6. Case, pivot, unpivot
-------------------------------------------------------------------------------


-- Case
-- Количество Общее-Женщины - Мужчины
select 
    count(*) as total_patients,
    count(case when w.m_or_w = 'M' then 1 end) as male_patients,
    count(case when w.m_or_w = 'W' then 1 end) as female_patients
from patient p
	join ward w on p.id_ward = w.id;


-- Пациент - возрастная группа
select 
    full_name as patient_name,
    case 
        when datediff(year, date_of_birth, getdate()) < 30 then N'Молодые (до 30)'
        when datediff(year, date_of_birth, getdate()) between 30 and 50 then N'Средний возраст (30-50)'
        else N'Старший возраст (50+)'
    end as age_group,
    datediff(year, date_of_birth, getdate()) as age
from patient
order by age_group, full_name;


-- Pivot Врачи(занятость)
select *
from (
    select 
        d.specialization,
        case 
            when p.id is not null then 'С пациентами'
            else 'Без пациентов'
        end as status
    from doctor d
    left join patient p on d.id = p.doctor_id
) as source_table
pivot (
    count(status)
    for status in ([С пациентами], [Без пациентов])
) as pivot_table;


-- Pivot отделение(сколько лежит по группам)
select *
from (
    select 
        hd.name as department_name,
        case 
            when datediff(year, p.date_of_birth, getdate()) < 30 then N'Молодые'
            when datediff(year, p.date_of_birth, getdate()) between 30 and 50 then N'Средние'
            else N'Старшие'
        end as age_group
    from 
    	patient p
	    join ward w on p.id_ward = w.id
	    join hospital_department hd on w.id_hospital_department = hd.id
) as source_table
pivot (
    count(age_group)
    for age_group in ([Молодые], [Средние], [Старшие])
) as pivot_table;

