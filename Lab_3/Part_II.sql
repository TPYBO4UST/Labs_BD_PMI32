--------------------------------------------------------------------------------
-------- 						II Часть 								--------
--------------------------------------------------------------------------------
-- a)  Найти пациентов, которые лежали в стационаре > 1 раза
select 
    p.full_name as patient_name,
    count(pa.id) as admission_count
from 
	patient p
	join patient_admission pa on p.id = pa.id_patient
group by 
	p.full_name
having 
	count(pa.id) > 1
order by 
	admission_count desc;

-- b)  Для каждого отделения вывести список палат, в которых есть свободные места
select 
    hd.name as department_name,
    w.number as ward_number,
    w.m_or_w as gender,
    w.number_of_beds as total_beds,
    w.number_of_beds - count(p.id) as free_beds
from 
	hospital_department hd
	join ward w on hd.id = w.id_hospital_department
	left join patient p on w.id = p.id_ward
group by 
	hd.name, w.number, w.m_or_w, w.number_of_beds
having 
	w.number_of_beds - count(p.id) > 0
order by 
	hd.name, w.number;

-- c)  Найти врачей, у которых в данный момент нет пациентов
select 
    d.full_name as doctor_name,
    d.specialization
from doctor d
where not exists (
    select 1 
    from patient p 
    where p.doctor_id = d.id
)
order by 
	d.specialization, d.full_name;

-- d)  Посчитать для каждого отделения количество свободных мужских и женских мест 
select 
    hd.name as department_name,
    w.m_or_w as gender,
    sum(w.number_of_beds) as total_beds,
    sum(w.number_of_beds) - count(p.id) as free_beds
from 
	hospital_department hd
	join ward w on hd.id = w.id_hospital_department
	left join patient p on w.id = p.id_ward
group by 
	hd.name, w.m_or_w
having 
	sum(w.number_of_beds) - count(p.id) > 0
order by 
	hd.name, w.m_or_w;

-- e) Статистика по диагнозам и возрастам
select 
    d.title as diagnosis_name,
    count(pa.id) as total_patients,
    count(case when datediff(year, p.date_of_birth, getdate()) < 18 then 1 end) as under_18,
    count(case when datediff(year, p.date_of_birth, getdate()) between 18 and 40 then 1 end) as between_18_40,
    count(case when datediff(year, p.date_of_birth, getdate()) > 40 then 1 end) as over_40
from 
	diagnosis d
	join patient_admission pa on d.[code-mkb10] = pa.key_diagnosis
	join patient p on pa.id_patient = p.id
group by 
	d.title
order by 
	total_patients desc;
