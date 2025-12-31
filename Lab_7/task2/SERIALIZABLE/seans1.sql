-- Устанавливаем уровень изоляции
set transaction isolation level serializable;

begin transaction;

-- Чтение пациентов с id_ward = 1
select count(*) as PatientCount from patient where id_ward = 1;

-- Ждем 10 секунд
waitfor DELAY '00:00:10';

-- Второе чтение
select count(*) as PatientCount from patient where id_ward = 1;

commit;