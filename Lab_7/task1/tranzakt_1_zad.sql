USE Hospital;

-- Исходные данные
select N'До транзакции' as Этап, * from patient where id = 1;

-- Транзакция с откатом
begin transaction;
update patient set full_name = N'Тест Откат' where id = 1;
select N'После update' as Этап, * from patient where id = 1;
rollback;
select N'После ROLLBACK' as Этап, * from patient where id = 1;

-- Транзакция с фиксацией
begin transaction;
update patient set full_name = N'Тест Фиксация' where id = 1;
select N'После update' as Этап, * from patient where id = 1;
commit;
select N'После COMMIT' as Этап, * from patient where id = 1;

-- Возвращаем исходное значение
update patient set full_name = N'Смирнов Алексей Викторович' where id = 1;