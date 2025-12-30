use Hospital;

-- drop role if exists HeadPhysician;
create role HeadPhysician;

-- drop role StaffRole;
create role StaffRole;

----------------------
-- Права Главврача
----------------------

-- На все таблицы с возможностью передачи
grant select, insert, update, delete on diagnosis to HeadPhysician with grant option;
grant select, insert, update, delete on doctor to HeadPhysician with grant option;
grant select, insert, update, delete on hospital_department to HeadPhysician with grant option;
grant select, insert, update, delete on patient_admission to HeadPhysician with grant option;
grant select, insert, update, delete on patient_card to HeadPhysician with grant option;
grant select, insert, update, delete on ward to HeadPhysician with grant option;
grant select, insert, update, delete on patient to HeadPhysician with grant option;

-- На создание таблиц
grant create table, alter, references to HeadPhysician;


-- Процедуры
grant execute on list_of_patients to HeadPhysician;

grant execute on free_ward_dep to HeadPhysician;
grant execute on avg_ward_workload to HeadPhysician;
grant execute on wards_below_average_workload to HeadPhysician;


----------------------
-- Права медперсонала
----------------------
grant select, insert on patient_admission to StaffRole;

grant select on diagnosis to StaffRole;
grant select on doctor to StaffRole;
grant select on hospital_department to StaffRole;
grant select on ward to StaffRole;

-- Ограничение на конфеденциальную информацию
--grant select (id, id_ward, full_name, date_of_birth, doctor_id) ON patient TO StaffRole;

grant select ON patient TO StaffRole;

-- Менять только врача и палату
grant update (id_ward, doctor_id) ON patient TO StaffRole;

-- Права на медкарты
grant select on patient_card to StaffRole;
grant insert on patient_card to StaffRole;
grant update (recommendations) ON patient_card TO StaffRole;

-- Запрет на удаление 
deny delete on patient to StaffRole;
deny delete on patient_admission to StaffRole;
deny delete on patient_card to StaffRole;

----------------------
-- Логин/Пароль
----------------------
create login headPhys
with password = 'head_pass', check_policy = off;

create login StaffR
with password = 'staff_pass', check_policy = off;

create user headPhys for login headPhys;
create user StaffR for login StaffR;

alter role HeadPhysician add member headPhys;
alter role StaffRole add member StaffR;


----------------------
-- Тесты
----------------------

-------------------------------------------
execute as user = 'headPhys';

execute as user = 'StaffR';
select full_name, id_ward from patient;

-- Запрет на просмотр конфиденциальной информации
select passport from patient;
delete from patient where id = 1;

-- Тест на запрет пользования процедуры
exec free_ward_dep 1;

revert;

select * from patient;


select user_name()




-------------------------------------------


-- SELECT name, type_desc, authentication_type_desc 
-- FROM sys.database_principals 


----------------------------
-- Маскирование через alter
----------------------------

-- Паспорт(первые и последние 2 цифры)
alter table patient
alter column passport add masked with (function = 'partial(2,"XX-XXXX-XX",2)')

-- Полис(Последние 4 цифры)
ALTER TABLE patient 
ALTER COLUMN medical_policy ADD MASKED WITH (FUNCTION = 'partial(0,"******",4)');

-- Телефон(последние 4 цифры)
ALTER TABLE patient 
ALTER COLUMN number_phone ADD MASKED WITH (FUNCTION = 'partial(0,"+7(***)***-**",4)');

-- Только улица
ALTER TABLE patient 
ALTER COLUMN address ADD MASKED WITH (FUNCTION = 'partial(0,"ул. *******, д.**, кв.**",0)');

GRANT UNMASK TO HeadPhysician;
DENY UNMASK TO StaffRole;


----------------------------
-- Маскирование через func
----------------------------

-- Альтернативный вариант: функция принимает саму дату
drop function if exists MaskDateByRole;
create function MaskDateByRole(@input_date DATE)
returns NVARCHAR(20)
as
begin
    if @input_date is null
        return null;
    else IF IS_MEMBER('HeadPhysician') = 1
        return CONVERT(NVARCHAR(10), @input_date, 104);
    else
        return '**/**/' + RIGHT(CAST(YEAR(@input_date) AS NVARCHAR(4)), 2);
    return NULL;
end;

drop view if exists vw_Patient_Secure;
create view vw_Patient_Secure as
select
    id,
    full_name,
    dbo.MaskDateByRole(date_of_birth) as date_of_birth,
    passport
from patient;

select * from patient;
select * from vw_Patient_Secure;

-- отзываем права на исходную таблицу
revoke select on patient to StaffRole;

-- Даем права только на представление
grant select on vw_Patient_Secure to StaffRole;
grant select on vw_Patient_Secure to HeadPhysician;
