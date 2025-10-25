--------------------------------------------------------------------------------
-- 2. Выборка из нескольких таблицы. 
--------------------------------------------------------------------------------


	-- 2.1 классиеский подход соединение(Декартово произведение + отсев)
-- Пациенты с ФИО врачей и номерами палат
select 
    p.full_name as patient_name,
    p.date_of_birth,
    p.number_phone,
    w.number as ward_number,
    d.full_name as doctor_name,
    d.specialization
from 
	patient p, ward w, doctor d
where 
	p.id_ward = w.id 
  	and p.doctor_id = d.id
order by 
	p.full_name;

	
-- История поступлений с названиями диагнозов
select 
    pa.id,
    p.full_name as patient_name,
    pa.date_of_receipt,
    diag.[code-mkb10] as diagnosis_code,
    diag.title AS diagnosis_name
from 
	patient_admission pa, patient p, diagnosis diag, ward w
where 
	pa.id_patient = p.id 
  	and pa.key_diagnosis = diag.[code-mkb10]
  	and p.id_ward = w.id
order by 
	pa.date_of_receipt desc;


	-- 2.2 Тоже самое, но с используя join
-- Пациенты с ФИО врачей и номерами палат
select 
    p.full_name patient_name,
    p.date_of_birth,
    p.number_phone,
    w.number ward_number,
    d.full_name doctor_name,
    d.specialization
from 
	patient p
	join ward w on p.id_ward = w.id
	join doctor d on p.doctor_id = d.id
order by 
	p.full_name;

	
-- История поступлений с названиями диагнозов
select 
    pa.id,
    p.full_name patient_name,
    pa.date_of_receipt,
    diag.[code-mkb10] diagnosis_code,
    diag.title diagnosis_name,
    w.number ward_number
from 
	patient_admission pa
	join patient p ON pa.id_patient = p.id
	join diagnosis diag ON pa.key_diagnosis = diag.[code-mkb10]
	join ward w ON p.id_ward = w.id
order by 
	pa.date_of_receipt desc;


	-- 2.3 Left join
-- Все отдления и их палаты(даже если палат нету)
select 
    hd.name departament_name,
    hd.number_of_beds total_beds,
    w.number ward_number,
    w.m_or_w gender,
    w.number_of_beds beds_in_ward
from 
	hospital_department hd
	left join ward w on hd.id = w.id_hospital_department
order by 
	hd.name, w.number;

	
-- Все врачи и их пациенты(даже если у врача нет пациентов)
select 
    d.full_name doctor_name,
    d.specialization,
    p.full_name patient_name
from 
	doctor d
	left join patient p on d.id = p.doctor_id
order by 
	d.full_name, p.full_name;


	-- 2.4 Right join(Его можно заменить left join-ом)
-- Все поступления и диагнозы
select 
    pa.date_of_receipt,
    p.full_name as patient_name,
    diag.[code-mkb10] as diagnosis_code,
    diag.title as diagnosis_name
from 
	diagnosis diag
right join patient_admission pa on diag.[code-mkb10] = pa.key_diagnosis
right join patient p on pa.id_patient = p.id
order by pa.date_of_receipt;


-- все пациенты и их врачи(как и писал, тоже самое что и left но развернуто)
select 
    p.full_name patients_name,
    p.date_of_birth,
    p.number_phone,
    d.full_name doctors_name,
    d.specialization
from 
	doctor d
	right join patient p on d.id = p.doctor_id
order by 
	p.full_name;


	-- 2.5 агрегатные функции
-- Статистика: Доктор - средний возраст пациента
select 
    d.full_name doctor_name,
    d.specialization,
	avg(datediff(year, p.date_of_birth, getdate())) as avg_patient_age
from 
	doctor d
	left join patient p on d.id = p.doctor_id
group by 
	d.full_name, d.specialization

	
-- Количество пацинетов по отделениям
select 
    hd.name departament_name,
    count(p.id) patient_count
from 
	hospital_department hd
	join ward w on hd.id = w.id_hospital_department
	join patient p on w.id = p.id_ward
group by 
	hd.name
order by 
	patient_count desc;


	--2.6 Having 
-- Врачи, у которых 2 пациента и более
select 
    d.full_name doctors_name,
    d.specialization,
    count(p.id) patient_count
from 
	doctor d
	join patient p on d.id = p.doctor_id
group by 
	d.full_name, d.specialization
having 
	count(p.id) >= 2
order by 
	count(p.id) desc;

	
-- Диагноз с 2-мя и более поступлениями
select 
    d.title as diagnosis_name,
    count(pa.id) diagnosis_count
from 
	diagnosis d
	join patient_admission pa on d.[code-mkb10] = pa.key_diagnosis
group by 
	d.title
having 
	count(pa.id) >= 2
order by 
	diagnosis_count desc;


	-- 2.7 In Exists
-- Пациенты, лежащие в Кардиологическом отделении
select 
    p.full_name as patient_name,
    p.date_of_birth
from 
	patient p
where p.id in (
    select distinct 
    	pa.id_patient
    from 
    	patient_admission pa
	    join patient p2 on pa.id_patient = p2.id
	    join ward w on p2.id_ward = w.id
	    join hospital_department hd on w.id_hospital_department = hd.id
    where 
    	hd.name = N'Кардиологическое отделение'
)
order by 
	p.full_name;

	
-- Заболевания, без единого поступления
select 
    d.title as diagnosis_name,
    d.[code-mkb10] as code
from diagnosis d
where not exists (
    select 1
    from patient_admission pa
    where pa.key_diagnosis = d.[code-mkb10]
)
order by d.title;


-- Палаты, где лежат пациенты, старше 60 лет
select 
    w.number as ward_number,
    w.m_or_w as gender,
    w.number_of_beds,
    p.full_name as patient_name,
    datediff(year, p.date_of_birth, getdate()) as age
from 
	ward w
	join patient p on w.id = p.id_ward
where w.id in (
    select p2.id_ward
    from patient p2
    where datediff(year, p2.date_of_birth, getdate()) > 60
)
order by 
	w.number, p.full_name;
