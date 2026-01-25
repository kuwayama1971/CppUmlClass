# frozen_string_literal: true

require "spec_helper"
require "create_uml_class"
require "ifdef_process"
require "fileutils"

RSpec.describe "create_uml_class" do
  let(:test_dir) { File.expand_path("fixtures/test_code", __dir__) }
  let(:pifdef) { IfdefProcess.new }
  let(:config) do
    {
      "exclude_path" => "",
      "define_hash" => {},
      "class_color_path1" => "",
      "class_color_path2" => "",
      "class_color_path3" => "",
      "default_class_color" => "",
      "class_color1" => "#Moccasin",
      "class_color2" => "#LightBlue",
      "class_color3" => "#LightPink"
    }
  end

  before do
    FileUtils.mkdir_p(test_dir)
  end

  after do
    FileUtils.rm_rf(test_dir)
  end

  describe "#create_uml_class" do
    before do
       # Inject @config into the top-level object where create_uml_class is defined
       # Since create_uml_class is defined at top-level, it's a private method on Object.
       # But when we call it here, we are inside RSpec example instance.
       # We need to set @config on the RSpec example instance.
       instance_variable_set(:@config, config)
    end

    it "generates UML for a simple class" do
      File.write(File.join(test_dir, "Simple.h"), <<~CPP)
        class Simple {
        public:
          void method1();
        private:
          int member1;
        };
      CPP

      uml = create_uml_class(pifdef, test_dir, "output.puml")
      expect(uml).to include("@startuml")
      expect(uml).to include("class Simple")
      expect(uml).to include("+ void method1()")
      expect(uml).to include("- int member1")
      expect(uml).to include("@enduml")
    end

    it "generates UML for inheritance" do
      File.write(File.join(test_dir, "Parent.h"), <<~CPP)
        class Parent { int p; };
      CPP
      File.write(File.join(test_dir, "Child.h"), <<~CPP)
        #include "Parent.h"
        class Child : public Parent { int c; };
      CPP

      uml = create_uml_class(pifdef, test_dir, "output.puml")
      expect(uml).to include("Child -[#black]--|> Parent")
    end
    
    it "generates UML for composition" do
       File.write(File.join(test_dir, "Component.h"), <<~CPP)
        class Component { int x; };
      CPP
      File.write(File.join(test_dir, "Composite.h"), <<~CPP)
        #include "Component.h"
        class Composite {
           Component comp;
        };
      CPP
      
      uml = create_uml_class(pifdef, test_dir, "output.puml")
      # The composition string format in create_uml_class.rb:
      # "#{o_list.name} *-[#{o_list.class_color}]-- #{co}"
      # default_class_color is ""
      expect(uml).to include("Composite *-[]-- Component") 
    end

    it "ignores excluded paths" do
      config["exclude_path"] = "Ignored"
      File.write(File.join(test_dir, "Ignored.h"), <<~CPP)
        class Ignored { int i; };
      CPP
      File.write(File.join(test_dir, "Included.h"), <<~CPP)
        class Included { int i; };
      CPP

      uml = create_uml_class(pifdef, test_dir, "output.puml")
      expect(uml).not_to include("class Ignored")
      expect(uml).to include("class Included")
    end

    it "handles access modifiers correctly" do
      File.write(File.join(test_dir, "DataHandler.h"), <<~CPP)
        class DataHandler {
        public:
          void publicMethod();
          int publicValue;
        protected:
          void protectedMethod();
          char buffer[512];
        private:
          void privateMethod();
          int internalCounter;
        };
      CPP

      uml = create_uml_class(pifdef, test_dir, "output.puml")
      expect(uml).to include("class DataHandler")
      expect(uml).to include("+ void publicMethod()")
      expect(uml).to include("+ int publicValue")
      expect(uml).to include("# void protectedMethod()")
      expect(uml).to include("# char buffer[512]")
      expect(uml).to include("- void privateMethod()")
      expect(uml).to include("- int internalCounter")
    end

    it "handles multiple inheritance" do
      File.write(File.join(test_dir, "IMovable.h"), <<~CPP)
        class IMovable {
        public:
          virtual ~IMovable();
          virtual void move();
        };
      CPP
      File.write(File.join(test_dir, "IEatable.h"), <<~CPP)
        class IEatable {
        public:
          virtual ~IEatable();
          virtual void eat();
        };
      CPP
      File.write(File.join(test_dir, "Robot.h"), <<~CPP)
        #include "IMovable.h"
        #include "IEatable.h"
        class Robot : public IMovable, public IEatable {
        public:
          void move();
          void eat();
        private:
          int batteryLevel;
        };
      CPP

      uml = create_uml_class(pifdef, test_dir, "output.puml")
      expect(uml).to include("class Robot")
      expect(uml).to include("Robot -[#black]--|> IMovable")
      expect(uml).to include("Robot -[#black]--|> IEatable")
    end

    it "handles complex composition with arrays" do
      File.write(File.join(test_dir, "Engine.h"), <<~CPP)
        class Engine {
        public:
          void start();
        private:
          int horsePower;
        };
      CPP
      File.write(File.join(test_dir, "Wheel.h"), <<~CPP)
        class Wheel {
        public:
          void rotate();
        private:
          int diameter;
        };
      CPP
      File.write(File.join(test_dir, "Car.h"), <<~CPP)
        #include "Engine.h"
        #include "Wheel.h"
        class Car {
        public:
          void drive();
        private:
          Engine engine;
          Wheel wheels[4];
          char licensePlate[20];
        };
      CPP

      uml = create_uml_class(pifdef, test_dir, "output.puml")
      expect(uml).to include("class Car")
      expect(uml).to include("class Engine")
      expect(uml).to include("class Wheel")
      expect(uml).to include("Car *-[]-- Engine")
      expect(uml).to include("Car *-[]-- Wheel")
    end

    it "handles abstract classes and virtual methods" do
      File.write(File.join(test_dir, "Shape.h"), <<~CPP)
        class Shape {
        public:
          virtual ~Shape();
          virtual void draw() = 0;
          virtual double getArea() = 0;
        protected:
          int colorR;
        };
      CPP
      File.write(File.join(test_dir, "Circle.h"), <<~CPP)
        #include "Shape.h"
        class Circle : public Shape {
        public:
          void draw();
          double getArea();
        private:
          float radius;
        };
      CPP

      uml = create_uml_class(pifdef, test_dir, "output.puml")
      expect(uml).to include("class Shape")
      expect(uml).to include("class Circle")
      expect(uml).to include("+ virtual void draw()")
      expect(uml).to include("+ virtual double getArea()")
      expect(uml).to include("Circle -[#black]--|> Shape")
    end

    it "handles namespace definitions" do
      File.write(File.join(test_dir, "Renderer.h"), <<~CPP)
        namespace Graphics {
          class Renderer {
          public:
            void render();
          private:
            int width;
          };

          class Texture {
          public:
            void load(const char* filename);
          private:
            int textureId;
          };
        }
      CPP

      uml = create_uml_class(pifdef, test_dir, "output.puml")
      expect(uml).to satisfy { |str| str.include?("class Graphics::Renderer") || str.include?("class Renderer") }
      expect(uml).to satisfy { |str| str.include?("class Graphics::Texture") || str.include?("class Texture") }
    end

    it "handles struct definitions" do
      File.write(File.join(test_dir, "Point.h"), <<~CPP)
        struct Point {
          int x;
          int y;
          void display();
        };
      CPP
      File.write(File.join(test_dir, "Rectangle.h"), <<~CPP)
        #include "Point.h"
        struct Rectangle {
          Point topLeft;
          int width;
          int height;
        };
      CPP

      uml = create_uml_class(pifdef, test_dir, "output.puml")
      expect(uml).to include("Point")
      expect(uml).to include("Rectangle")
      expect(uml).to include("+ void display()")
    end

    it "handles pointer members and aggregation" do
      File.write(File.join(test_dir, "Department.h"), <<~CPP)
        class Department {
        public:
          void setName(const char* name);
        private:
          char departmentName[100];
        };
      CPP
      File.write(File.join(test_dir, "Employee.h"), <<~CPP)
        #include "Department.h"
        class Employee {
        public:
          void setDepartment(Department* dept);
        private:
          Department* department;
          int salary;
        };
      CPP

      uml = create_uml_class(pifdef, test_dir, "output.puml")
      expect(uml).to include("class Employee")
      expect(uml).to include("class Department")
      expect(uml).to include("Employee")
      expect(uml).to include("Department")
    end

    it "handles template classes" do
      File.write(File.join(test_dir, "Stack.h"), <<~CPP)
        template<typename T>
        class Stack {
        public:
          void push(T value);
          T pop();
          bool isEmpty();
        private:
          T* data;
          int size;
        };
      CPP

      uml = create_uml_class(pifdef, test_dir, "output.puml")
      expect(uml).to include("class Stack")
      expect(uml).to include("+ void push(T value)")
      expect(uml).to include("+ T pop()")
    end

    it "handles observer pattern and complex relationships" do
      File.write(File.join(test_dir, "Observer.h"), <<~CPP)
        class Observer {
        public:
          virtual ~Observer();
          virtual void update();
        };
      CPP
      File.write(File.join(test_dir, "Subject.h"), <<~CPP)
        #include "Observer.h"
        class Subject {
        public:
          void attach(Observer* observer);
          void detach(Observer* observer);
        protected:
          Observer* observers[10];
        };
      CPP
      File.write(File.join(test_dir, "DataDisplay.h"), <<~CPP)
        #include "Observer.h"
        class DataDisplay : public Observer {
        public:
          void update();
          void display();
        };
      CPP

      uml = create_uml_class(pifdef, test_dir, "output.puml")
      expect(uml).to include("class Observer")
      expect(uml).to include("class Subject")
      expect(uml).to include("class DataDisplay")
      expect(uml).to include("DataDisplay -[#black]--|> Observer")
    end
  end
end
