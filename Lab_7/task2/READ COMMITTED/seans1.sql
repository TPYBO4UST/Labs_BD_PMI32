set transaction isolation level read committed;

begin transaction;

-- 1 чтение
select address from patient where id = 2;

-- Ждем 10 секунд
waitfor DELAY '00:00:10';

-- 2 чтение тех же данных
select address from patient where id = 2;

commit;