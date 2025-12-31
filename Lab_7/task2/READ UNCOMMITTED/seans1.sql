-- READ UNCOMMITTED грязное чтение
-- Сеанс 1
-- Устанавливаем уровень изоляции
set transaction isolation level read uncommitted;

-- Начинаем транзакцию
begin transaction;

-- Обновляем данные
update patient set address = N'Новый адрес (грязное чтение)' where id = 1;

-- Ждем 10 секунд для возможности чтения из второго сеанса
waitfor DELAY '00:00:10';

-- Откатываем изменения
rollback;