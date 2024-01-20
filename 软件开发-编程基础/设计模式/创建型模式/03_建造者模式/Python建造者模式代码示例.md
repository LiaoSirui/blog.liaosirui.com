![image-20240116201110916](.assets/Python建造者模式代码示例/image-20240116201110916.png)

**生成器** （Builder） 接口声明在所有类型生成器中通用的产品构造步骤

```python
"""Builder Pattern
"""
from __future__ import annotations
from abc import ABC, abstractmethod
from typing import Any


class Builder(ABC):
    """
    The Builder interface specifies methods for creating the different parts of
    the Product objects.
    """

    @property
    @abstractmethod
    # pylint: disable=missing-function-docstring
    def product(self) -> None:
        pass

    @abstractmethod
    # pylint: disable=missing-function-docstring
    def produce_part_a(self) -> "Builder":
        pass

    @abstractmethod
    # pylint: disable=missing-function-docstring
    def produce_part_b(self) -> "Builder":
        pass

    @abstractmethod
    # pylint: disable=missing-function-docstring
    def produce_part_c(self) -> "Builder":
        pass
```

**具体生成器** （Concrete Builders） 提供构造过程的不同实现。 具体生成器也可以构造不遵循通用接口的产品

```python
class ConcreteBuilder1(Builder):
    """
    The Concrete Builder classes follow the Builder interface and provide
    specific implementations of the building steps. Your program may have
    several variations of Builders, implemented differently.
    """

    def __init__(self) -> None:
        """
        A fresh builder instance should contain a blank product object, which
        is used in further assembly.
        """
        self.reset()

    def reset(self) -> None:
        """
        Reset the existing product to initial state.
        """
        self._product = Product1()

    @property
    def product(self) -> Product1:
        """
        Concrete Builders are supposed to provide their own methods for
        retrieving results. That's because various types of builders may create
        entirely different products that don't follow the same interface.
        Therefore, such methods cannot be declared in the base Builder
        interface (at least in a statically typed programming language).

        Usually, after returning the end result to the client, a builder
        instance is expected to be ready to start producing another product.
        That's why it's a usual practice to call the reset method at the end of
        the `getProduct` method body. However, this behavior is not mandatory,
        and you can make your builders wait for an explicit reset call from the
        client code before disposing of the previous result.
        """
        product = self._product
        self.reset()
        return product

    def produce_part_a(self) -> "ConcreteBuilder1":
        self._product.add("PartA1")
        return self

    def produce_part_b(self) -> "ConcreteBuilder1":
        self._product.add("PartB1")
        return self

    def produce_part_c(self) -> "ConcreteBuilder1":
        self._product.add("PartC1")
        return self
```

**产品** （Products） 是最终生成的对象。 由不同生成器构造的产品无需属于同一类层次结构或接口

```python
class Product1:
    """
    It makes sense to use the Builder pattern only when your products are quite
    complex and require extensive configuration.

    Unlike in other creational patterns, different concrete builders can
    produce unrelated products. In other words, results of various builders may
    not always follow the same interface.
    """

    def __init__(self) -> None:
        self.parts = []

    def add(self, part: Any) -> None:
        """
        Product1 class has a method that adds a new part to the product.
        """
        self.parts.append(part)

    def list_parts(self) -> None:
        """
        Product1 class has a method that lists all parts of the product.
        """
        print(f"Product parts: {', '.join(self.parts)}", end="")
```

**主管** （Director） 类定义调用构造步骤的顺序， 这样你就可以创建和复用特定的产品配置

```python
class Director:
    """
    The Director is only responsible for executing the building steps in a
    particular sequence. It is helpful when producing products according to a
    specific order or configuration. Strictly speaking, the Director class is
    optional, since the client can control builders directly.
    """

    def __init__(self) -> None:
        self._builder = None

    @property
    def builder(self) -> Builder:
        """
        The Director works with any builder instance that the client code
        """
        return self._builder

    @builder.setter
    def builder(self, _builder: "Builder") -> None:
        """
        The Director works with any builder instance that the client code
        passes to it. This way, the client code may alter the final type of the
        newly assembled product.
        """
        self._builder = _builder

    def build_minimal_viable_product(self) -> None:
        """
        The Director can construct several product variations using the same
        building steps.
        """
        self.builder.produce_part_a()

    def build_full_featured_product(self) -> None:
        """
        The Director can construct several product variations using the same
        building steps.
        """
        self.builder.produce_part_a()\
            .builder.produce_part_b()\
            .builder.produce_part_c()
```

**客户端** （Client） 必须将某个生成器对象与主管类关联。 一般情况下， 你只需通过主管类构造函数的参数进行一次性关联即可。 此后主管类就能使用生成器对象完成后续所有的构造任务。 但在客户端将生成器对象传递给主管类制造方法时还有另一种方式。 在这种情况下， 你在使用主管类生产产品时每次都可以使用不同的生成器

```python
def main() -> None:
    """
    The client code creates a builder object, passes it to the director and
    then initiates the construction process. The end result is retrieved from
    the builder object.
    """
    director = Director()
    builder = ConcreteBuilder1()
    director.builder = builder

    print("Standard basic product: ")
    director.build_minimal_viable_product()
    builder.product.list_parts()

    print("\n")

    print("Standard full featured product: ")
    director.build_full_featured_product()
    builder.product.list_parts()

    print("\n")

    # Remember, the Builder pattern can be used without a Director class.
    print("Custom product: ")
    builder.produce_part_a()\
        .produce_part_b()
    builder.product.list_parts()
```

