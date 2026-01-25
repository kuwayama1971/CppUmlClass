#ifndef BASIC_CLASS_H
#define BASIC_CLASS_H

// 基本的なクラス定義
class SimpleClass {
public:
  SimpleClass();
  ~SimpleClass();
  void doSomething();
  int getValue();

private:
  int value;
  char buffer[256];
};

#endif // BASIC_CLASS_H
