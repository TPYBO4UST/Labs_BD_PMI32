-- CREATE DATABASE Hospital_Graph;

use Hospital_Graph;

drop table if exists TREATS;
drop table if exists HAS_DIAGNOSIS;
drop table if exists ASSIGNED_TO;
drop table if exists LOCATED_IN;
drop table if exists HEADED_BY;
drop table if exists ADMITTED_WITH;
drop table if exists HAS_CARD;


-- Удаляем узлы 
drop table if exists Patient;
drop table if exists Doctor;
drop table if exists Diagnosis;
drop table if exists Ward;
drop table if exists Department;

-- Таблицы узлов
create table Patient (
    id INT PRIMARY KEY,
    full_name NVARCHAR(255),
    passport NVARCHAR(255),
    medical_policy NVARCHAR(255),
    number_phone NVARCHAR(255),
    address NVARCHAR(255),
    date_of_birth DATE
) as NODE;

create table Doctor (
    id INT PRIMARY KEY,
    full_name NVARCHAR(255),
    specialization NVARCHAR(255)
) as NODE;

create table Diagnosis (
    code_mkb10 VARCHAR(6) PRIMARY KEY,
    title NVARCHAR(255)
) as NODE;

create table Ward (
    id INT PRIMARY KEY,
    number SMALLINT,
    number_of_beds SMALLINT,
    m_or_w CHAR(1)
) as NODE;

create table Department (
    id INT PRIMARY KEY,
    name NVARCHAR(255),
    number_of_beds SMALLINT,
    number_of_cameras SMALLINT
) as NODE;

-- Ребра
create table TREATS as EDGE;
create table HAS_DIAGNOSIS as EDGE;
create table ASSIGNED_TO as EDGE;
create table LOCATED_IN as EDGE;
create table HEADED_BY as EDGE;
create table ADMITTED_WITH as EDGE;
create table HAS_CARD as EDGE;
