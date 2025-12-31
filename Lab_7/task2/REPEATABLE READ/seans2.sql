-- Окно 2 - Сеанс 2
use Hospital;

-- Ждем, чтобы сеанс 1 начал транзакцию
waitfor DELAY '00:00:05';

set transaction isolation level repeatable read;

begin transaction;

-- Добавляем пациента в палату 1
insert into patient (id_ward, full_name, passport, medical_policy, number_phone, address, date_of_birth, doctor_id)
values (1, N'Фантомный Пациент', '8818888888', '8818888888', '+78188888881', 
        N'Тестовый адрес для фантома', '1995-05-05', 1);
commit;

