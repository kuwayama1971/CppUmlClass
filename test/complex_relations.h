#ifndef COMPLEX_RELATIONS_H
#define COMPLEX_RELATIONS_H

// 複雑な関係性の例
class Department {
public:
  Department();
  ~Department();
  void setName(const char* name);

private:
  char departmentName[100];
};

class Project {
public:
  Project();
  ~Project();
  void setDepartment(Department* dept);
  void startProject();

private:
  Department* department;
  int projectId;
};

class Person {
public:
  Person();
  ~Person();
  void assignToProject(Project* project);
  void setDepartment(Department* dept);

protected:
  char name[100];
  int employeeId;
  Department* department;
};

class Employee : public Person {
public:
  Employee();
  ~Employee();
  void assignToProject(Project* project);
  void workOnProject();

private:
  Project* currentProject;
  int salary;
};

class Manager : public Employee {
public:
  Manager();
  ~Manager();
  void superviseEmployee(Employee* emp);
  void assignWork();

private:
  Employee* supervisedEmployees[10];
  int supervisedCount;
};

#endif // COMPLEX_RELATIONS_H
