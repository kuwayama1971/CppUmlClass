#ifndef INHERITANCE_H
#define INHERITANCE_H

// 基底クラス
class Animal {
public:
  Animal();
  virtual ~Animal();
  virtual void makeSound();
  void setName(const char* name);

protected:
  char name[100];
  int age;
};

// 単一継承
class Dog : public Animal {
public:
  Dog();
  ~Dog();
  void makeSound();
  void fetch();

private:
  bool hasTail;
};

// 多重継承の例
class IMovable {
public:
  virtual ~IMovable();
  virtual void move();
};

class IEatable {
public:
  virtual ~IEatable();
  virtual void eat();
};

class Robot : public IMovable, public IEatable {
public:
  Robot();
  ~Robot();
  void move();
  void eat();

private:
  int batteryLevel;
};

#endif // INHERITANCE_H
