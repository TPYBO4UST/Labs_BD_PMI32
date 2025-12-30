use Hospital_Graph;

-- врачи и количество их пациентов
with doctor_patient_graph as (
    select 
        d.full_name as doctor_name,
        d.specialization,
        p.id as patient_id
    from Doctor d, Patient p, TREATS t
    where match(d-(t)->p)
)
select 
    doctor_name,
    specialization,
    count(patient_id) as patient_count
from doctor_patient_graph
group by doctor_name, specialization
order by patient_count desc;

-- Подсчет пациентов по отделениям
with department_patient_graph as (
    select 
        dept.name as department_name,
        pat.id as patient_id
    from Patient pat, Ward w, Department dept,
         ASSIGNED_TO a, LOCATED_IN l
    where match(pat-(a)->w-(l)->dept)
)
select 
    department_name,
    COUNT(distinct patient_id) as patient_count
from department_patient_graph
group by department_name
order by patient_count desc;