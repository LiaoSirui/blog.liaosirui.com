```go
package main

import (
	"fmt"
	"sync"
)

func printAnimal(wg *sync.WaitGroup, cat chan bool, dog chan bool, animal string, times int) {
	defer wg.Done()
	for i := 0; i < times; i++ {
		<-cat
		fmt.Println(animal)
		dog <- true
	}
}

func main() {
	var wg sync.WaitGroup
	wg.Add(2)

	cat := make(chan bool, 1)
	dog := make(chan bool, 1)

	cat <- true

	go printAnimal(&wg, cat, dog, "cat", 10)
	go printAnimal(&wg, dog, cat, "dog", 10)

	wg.Wait()
}

```

循环打印猫和狗各十次

猫狗队列