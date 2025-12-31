-- Окно 1 - Сеанс 1
use Hospital;
set transaction isolation level repeatable read;

begin transaction;

select COUNT(*) as PatientCount from patient where id_ward = 1;

waitfor DELAY '00:00:15';

select count(*) as PatientCount from patient where id_ward = 1;

commit;