-- Сеанс 2
-- Устанавливаем уровень изоляции
set transaction isolation level read uncommitted;

-- Читаем данные во время выполнения транзакции в сеансе 1
begin transaction;
select address from patient where id = 1;
commit;