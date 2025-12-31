set transaction isolation level read committed;

-- Меняем данные после первого чтения в сеансе 1
begin transaction;
update patient set address = N'Измененный адрес' where id = 2;
commit;