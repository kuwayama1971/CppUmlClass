#ifndef TEMPLATE_EXAMPLE_H
#define TEMPLATE_EXAMPLE_H

// テンプレートクラスの例
template<typename T>
class Stack {
public:
  Stack();
  ~Stack();
  void push(T value);
  T pop();
  bool isEmpty();

private:
  T* data;
  int size;
  int capacity;
};

template<typename K, typename V>
class Dictionary {
public:
  Dictionary();
  ~Dictionary();
  void insert(K key, V value);
  V lookup(K key);
  bool contains(K key);

private:
  struct Entry {
    K key;
    V value;
  };
  Entry* entries;
  int entryCount;
};

// テンプレート継承の例
template<typename T>
class Container {
public:
  virtual ~Container();
  virtual void add(T item);
  virtual T get(int index);

protected:
  T* items;
  int count;
};

template<typename T>
class Vector : public Container<T> {
public:
  Vector();
  ~Vector();
  void add(T item);
  T get(int index);

private:
  int capacity;
};

#endif // TEMPLATE_EXAMPLE_H
