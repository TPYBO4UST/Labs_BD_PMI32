use Hospital_Graph;


-------------------
-- Заполняем узлы
-------------------


insert into Patient (id, full_name, passport, medical_policy, number_phone, address, date_of_birth)
select 
    p.id,
    p.full_name,
    p.passport,
    p.medical_policy,
    p.number_phone,
    p.address,
    p.date_of_birth
from Hospital.dbo.patient p;

insert into Doctor (id, full_name, specialization)
select 
    d.id,
    d.full_name,
    d.specialization
from Hospital.dbo.doctor d;

insert into Diagnosis (code_mkb10, title)
select 
    [code-mkb10],
    title
from Hospital.dbo.diagnosis;

insert into Ward (id, number, number_of_beds, m_or_w)
select 
    w.id,
    w.number,
    w.number_of_beds,
    w.m_or_w
from Hospital.dbo.ward w;

insert into Department (id, name, number_of_beds, number_of_cameras)
select 
    hd.id,
    hd.name,
    hd.number_of_beds,
    hd.number_of_cameras
from Hospital.dbo.hospital_department hd;

-- TREATS 
-- врач лечит пациента
insert into TREATS ($from_id, $to_id)
select 
    (select $node_id from Doctor where id = p.doctor_id),
    (select $node_id from Patient where id = p.id)
from Hospital.dbo.patient p
where p.doctor_id IS NOT NULL;

-- HAS_DIAGNOSIS 
-- пациент имеет основной диагноз через палату
insert into HAS_DIAGNOSIS ($from_id, $to_id)
select DISTINCT
    (select $node_id from Patient where id = p.id),
    (select $node_id from Diagnosis where code_mkb10 = w.key_diagnosis)
from Hospital.dbo.patient p
JOIN Hospital.dbo.ward w ON p.id_ward = w.id
where w.key_diagnosis IS NOT NULL;

-- ASSIGNED_TO 
-- пациент привязан к палате
insert into ASSIGNED_TO ($from_id, $to_id)
select 
    (select $node_id from Patient where id = p.id),
    (select $node_id from Ward where id = p.id_ward)
from Hospital.dbo.patient p
where p.id_ward IS NOT NULL;

-- LOCATED_IN 
-- палата находится в отделении
insert into LOCATED_IN ($from_id, $to_id)
select 
    (select $node_id from Ward where id = w.id),
    (select $node_id from Department where id = w.id_hospital_department)
from Hospital.dbo.ward w
where w.id_hospital_department IS NOT NULL;

-- HEADED_BY 
-- отделение возглавляется врачом
insert into HEADED_BY ($from_id, $to_id)
select 
    (select $node_id from Department where id = hd.id),
    (select $node_id from Doctor where id = hd.doctor_id)
from Hospital.dbo.hospital_department hd
where hd.doctor_id IS NOT NULL;

-- ADMITTED_WITH 
-- пациент поступил с диагнозом
insert into ADMITTED_WITH ($from_id, $to_id)
select DISTINCT
    (select $node_id from Patient where id = pa.id_patient),
    (select $node_id from Diagnosis where code_mkb10 = pa.key_diagnosis)
from Hospital.dbo.patient_admission pa;

-- HAS_CARD 
-- пациент имеет карту с врачом
insert into HAS_CARD ($from_id, $to_id)
select DISTINCT
    (select $node_id from Patient where id = pc.id_patient),
    (select $node_id from Doctor where id = pc.doctor_id)
from Hospital.dbo.patient_card pc;

-- связи диагнозов для всех поступлений пациентов
insert into HAS_DIAGNOSIS ($from_id, $to_id)
select DISTINCT
    (select $node_id from Patient where id = pa.id_patient),
    (select $node_id from Diagnosis where code_mkb10 = pa.key_diagnosis)
from Hospital.dbo.patient_admission pa
where NOT EXISTS (
    select 1 from HAS_DIAGNOSIS hd
    JOIN Patient p ON hd.$from_id = p.$node_id
    JOIN Diagnosis d ON hd.$to_id = d.$node_id
    where p.id = pa.id_patient AND d.code_mkb10 = pa.key_diagnosis
);
