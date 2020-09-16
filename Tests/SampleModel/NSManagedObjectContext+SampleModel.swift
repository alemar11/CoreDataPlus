// CoreDataPlus

import Foundation
import CoreData

extension NSManagedObjectContext {
  /// Fills the context with a sample data set. (145 objects)
  func fillWithSampleData() {
    let context = self

    let person1 = Person(context: context)
    person1.firstName = "Edythe"
    person1.lastName = "Moreton"

    let person2 = Person(context: context)
    person2.firstName = "Ellis"
    person2.lastName = "Khoury"

    let person3 = Person(context: context)
    person3.firstName = "Faron"
    person3.lastName = "Moreton"

    let person4 = Person(context: context)
    person4.firstName = "Darin"
    person4.lastName = "Meadow"

    let person5 = Person(context: context)
    person5.firstName = "Juliana"
    person5.lastName = "Pyke"

    let person6 = Person(context: context)
    person6.firstName = "Victoria"
    person6.lastName = "Distefano"

    let person7 = Person(context: context)
    person7.firstName = "Wardell"
    person7.lastName = "Reynolds"

    let person8 = Person(context: context)
    person8.firstName = "Morgan"
    person8.lastName = "Wigner"

    let person9 = Person(context: context)
    person9.firstName = "Gavin"
    person9.lastName = "Chuang"

    let person10 = Person(context: context)
    person10.firstName = "Bret"
    person10.lastName = "Munger"

    let person11 = Person(context: context)
    person11.firstName = "Theodora"
    person11.lastName = "Stone"

    let person12 = Person(context: context)
    person12.firstName = "Bishop"
    person12.lastName = "Boosalis"

    let person13 = Person(context: context)
    person13.firstName = "Jerrod"
    person13.lastName = "Wade"

    let person14 = Person(context: context)
    person14.firstName = "Ross"
    person14.lastName = "Hurowitz"

    let person15 = Person(context: context)
    person15.firstName = "Victoria"
    person15.lastName = "Coster"

    let person16 = Person(context: context)
    person16.firstName = "Lorayne"
    person16.lastName = "Gleaves"

    let person17 = Person(context: context)
    person17.firstName = "Bret"
    person17.lastName = "Nabokov"

    let person18 = Person(context: context)
    person18.firstName = "Vaughn"
    person18.lastName = "Gleaves"

    let person19 = Person(context: context)
    person19.firstName = "Mark"
    person19.lastName = "Alves"

    let person20 = Person(context: context)
    person20.firstName = "Alex"
    person20.lastName = "Rathbun"

    /// FIAT
    let car1 = Car(context: context)
    car1.maker = "FIAT"
    car1.model = "Panda"
    car1.numberPlate = "1"

    let car2 = Car(context: context)
    car2.maker = "FIAT"
    car2.model = "Punto"
    car2.numberPlate = "2"

    let car3 = Car(context: context)
    car3.maker = "FIAT"
    car3.model = "Tipo"
    car3.numberPlate = "3"

    /// Alfa Romeo
    let car4 = Car(context: context)
    car4.maker = "Alfa Romeo"
    car4.model = "Giulietta"
    car4.numberPlate = "4"

    let car5 = Car(context: context)
    car5.maker = "Alfa Romeo"
    car5.model = "Giulia"
    car5.numberPlate = "5"

    let car6 = Car(context: context)
    car6.maker = "Alfa Romeo"
    car6.model = "Mito"
    car6.numberPlate = "6"

    /// Volkswagen
    let car7 = Car(context: context)
    car7.maker = "Volkswagen"
    car7.model = "Golf"
    car7.numberPlate = "7"

    let car8 = Car(context: context)
    car8.maker = "Volkswagen"
    car8.model = "Polo"
    car8.numberPlate = "8"

    /// Kia
    let car9 = Car(context: context)
    car9.maker = "Kia"
    car9.model = "Rio"
    car9.numberPlate = "9"

    let car10 = Car(context: context)
    car10.maker = "Kia"
    car10.model = "Sportage"
    car10.numberPlate = "10"

    let car11 = Car(context: context)
    car11.maker = "Kia"
    car11.model = "Soul"
    car11.numberPlate = "11"

    let car12 = Car(context: context)
    car12.maker = "Kia"
    car12.model = "Carens"
    car12.numberPlate = "12"

    /// Renault
    let car13 = Car(context: context)
    car13.maker = "Renault"
    car13.model = "Twingo"
    car13.numberPlate = "13"

    let car14 = Car(context: context)
    car14.maker = "Renault"
    car14.model = "Clio"
    car14.numberPlate = "14"

    let car15 = Car(context: context)
    car15.maker = "Renault"
    car15.model = "Megane"
    car15.numberPlate = "15"

    /// Sport Car
    let sportCar1 = SportCar(context: context)
    sportCar1.maker = "BMW"
    sportCar1.model = "M6 Coupe"
    sportCar1.numberPlate = "200"

    let sportCar2 = SportCar(context: context)
    sportCar2.maker = "Mercedes-Benz"
    sportCar2.model = "AMG GT S"
    sportCar2.numberPlate = "201"

    let sportCar3 = SportCar(context: context)
    sportCar3.maker = "Maserati"
    sportCar3.model = "GranTurismo MC"
    sportCar3.numberPlate = "202"

    let sportCar4 = SportCar(context: context)
    sportCar4.maker = "McLaren"
    sportCar4.model = "570GT"
    sportCar4.numberPlate = "203"

    let sportCar5 = SportCar(context: context)
    sportCar5.maker = "Lamborghini"
    sportCar5.model = "Aventador LP750-4"
    sportCar5.numberPlate = "204"

    /// Expensive Sport Car
    let expensiveSportCar1 = ExpensiveSportCar(context: context)
    expensiveSportCar1.maker = "BMW"
    expensiveSportCar1.model = "M6 Coupe"
    expensiveSportCar1.numberPlate = "300"
    expensiveSportCar1.isLimitedEdition = true

    let expensiveSportCar2 = ExpensiveSportCar(context: context)
    expensiveSportCar2.maker = "Mercedes-Benz"
    expensiveSportCar2.model = "AMG GT S"
    expensiveSportCar2.numberPlate = "301"
    expensiveSportCar2.isLimitedEdition = true

    let expensiveSportCar3 = ExpensiveSportCar(context: context)
    expensiveSportCar3.maker = "Maserati"
    expensiveSportCar3.model = "GranTurismo MC"
    expensiveSportCar3.numberPlate = "302"
    expensiveSportCar3.isLimitedEdition = false

    let expensiveSportCar4 = ExpensiveSportCar(context: context)
    expensiveSportCar4.maker = "McLaren"
    expensiveSportCar4.model = "570GT"
    expensiveSportCar4.numberPlate = "303"
    expensiveSportCar4.isLimitedEdition = false

    let expensiveSportCar5 = ExpensiveSportCar(context: context)
    expensiveSportCar5.maker = "Lamborghini"
    expensiveSportCar5.model = "Aventador LP750-4"
    expensiveSportCar5.numberPlate = "304"
    expensiveSportCar5.isLimitedEdition = false

    /// car15, sportCar5, expensiveSportCar4 and expensiveSportCar5 do not have an owner
    person1.cars = [car1]
    person2.cars = [car2]
    person3.cars = [car3, expensiveSportCar1]
    person4.cars = [car4]
    person5.cars = [car5, expensiveSportCar2, expensiveSportCar3]
    person6.cars = [car6]
    person7.cars = [sportCar1, sportCar2]
    person8.cars = [car7]
    person9.cars = [sportCar3]
    person10.cars = [car8, car9]
    person11.cars = [car10, car11, car12] // and a lots of panda 🚗
    person12.cars = [sportCar4]
    person13.cars = [car13, car14]
    person14.cars = [car13, car14]

    var cars = [Car]()
    for i in 100..<200 {
      let car = Car(context: context)
      car.maker = "FIAT"
      car.model = "Panda"
      car.numberPlate = "\(i)"
      cars.append(car)
    }
    person11._cars = Set(cars)
  }
}
