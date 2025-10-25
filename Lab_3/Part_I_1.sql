-------------------------------------------------------------------------------
-- Лабораторная работа №3
-------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- 1. Выборка из одной таблицы
--------------------------------------------------------------------------------


	-- 1.1 выборка из одной таблицы(сортировка)
select 
	full_name doctor_name, specialization
from 
	doctor
order by doctor_name asc, specialization desc;


	-- 1.2 условие where (2-3 запроса)
-- название улицы начинается на С
select 
	full_name patient_name, address
from 
	patient
where address like N'____С%';


-- Врачи офтальмологи
select 	
	d.full_name doctor_name, d.specialization 
from 
	doctor d 
where 
	d.specialization like N'Офтальмолог'
	
	
	-- 1.3 Агрегатные функции(с группировкой и без)
-- Всего врачей в больнице
select
	count(d.full_name ) count_doctor
from
	doctor d 

	
-- Каких врачей в больнице больше всего(специализация)
select top(1) with ties
	d.specialization, count(d.specialization) as count_spec
from
	doctor d 
group by
	d.specialization
order by
	count_spec desc
	
	
-- Самое распространенное заболевание в стационаре(его код)
select top(1) with ties
	w.key_diagnosis, count(w.key_diagnosis) as count_diag
from 
	ward w
group by
	w.key_diagnosis
order by
	count_diag desc

	
	-- 1.4 Подведение подытога
-- rollup: по специализациям (средняя длинна имени + кол врачей)
select 
    specialization,
    count(*) doctors_count,
    avg(LEN(full_name)) avg_name_length
from 
	doctor
group by 
	rollup (specialization)
order by 
	specialization;

	
-- cube: все комбинации пола и количества палаты
select 
    coalesce(m_or_w, N'ВСЕ') as gender,
    coalesce(cast(number_of_beds as varchar(10)), N'ВСЕ') as beds,
    count(*) as ward_count
from 
	ward
group by 
	cube (m_or_w, number_of_beds)
order by 
	m_or_w, 
	number_of_beds;

