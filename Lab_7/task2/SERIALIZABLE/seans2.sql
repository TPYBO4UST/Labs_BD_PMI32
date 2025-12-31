set transaction isolation level serializable;

-- Пытаемся добавить нового пациента
begin transaction;
insert into patient (id_ward, full_name, passport, medical_policy, number_phone, address, date_of_birth, doctor_id)
values (1, N'Новый Пациент SERIALIZABLE', '7717777777', '7777717777', '+77771777777', N'Новый адрес', '1990-01-01', 1);
commit;