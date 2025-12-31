// 1. Все документы без _id
db.restaurants.find(
    {},
    {
        _id: 0,
        restaurant_id: 1,
        name: 1,
        borough: 1,
        cuisine: 1
    }
)

// 2. Первые 5 ресторанов из Bronx по алфавиту
db.restaurants.find(
    { borough: "Bronx" },
    {
        _id: 0,
        restaurant_id: 1,
        name: 1,
        borough: 1,
        cuisine: 1
    }
)
.sort({ name: 1 })
.limit(5)

// 3. Рестораны с оценкой 80-100
db.restaurants.find({
  "grades.score": { $gt: 80, $lt: 100 }
}).limit(5)

// 4. Не American кухня, оценка A, не Brooklyn
db.restaurants.find({
  cuisine: { $ne: "American" },
  "grades.grade": "A",
  borough: { $ne: "Brooklyn" }
}).sort({ cuisine: -1 }).limit(5)

// 5. Название начинается с "Wil"
db.restaurants.find({
  name: /^Wil/
}, {
  _id: 0,
  restaurant_id: 1,
  name: 1,
  borough: 1,
  cuisine: 1
})

// 6. Bronx и (American или Chinese)
db.restaurants.find({
  borough: "Bronx",
  cuisine: { $in: ["American", "Chinese"] }
}, {
  _id: 0,
  name: 1,
  cuisine: 1
}).limit(10)

// 7. Оценка A с score=9 в определенную дату
db.restaurants.find({
  "grades": {
    $elemMatch: {
      "grade": "A",
      "score": 9,
      "date": ISODate("2014-08-11T00:00:00Z")
    }
  }
}, {
  _id: 0,
  restaurant_id: 1,
  name: 1,
  grades: 1
})

// 8. Количество ресторанов по районам и кухням
db.restaurants.aggregate([
  {
    $group: {
      _id: {
        borough: "$borough",
        cuisine: "$cuisine"
      },
      count: { $sum: 1 }
    }
  },
  {
    $project: {
      _id: 0,
      borough: "$_id.borough",
      cuisine: "$_id.cuisine",
      count: 1
    }
  },
  { $sort: { borough: 1, cuisine: 1 } }
])

// 9. Ресторан с минимальной суммой баллов в Bronx
db.restaurants.aggregate([
  { $match: { borough: "Bronx" } },
  {
    $addFields: {
      totalScore: {
        $sum: "$grades.score"
      }
    }
  },
  { $sort: { totalScore: 1 } },
  { $limit: 1 }
])

// 10. Добавить любимый ресторан:
db.restaurants.insertOne({
  restaurant_id: "99999999",
  name: "Мой любимый ресторан",
  borough: "Manhattan",
  cuisine: "Russian",
  address: {
    building: "123",
    street: "Main Street",
    zipcode: "10001",
    coord: [-73.9857, 40.7484]
  },
  grades: [
    { date: new Date(), grade: "A", score: 10 }
  ]
})

// 11. Добавить время работы:
db.restaurants.updateOne(
  { restaurant_id: "99999999" },
  {
    $set: {
      working_hours: {
        monday: "09:00-22:00",
        tuesday: "09:00-22:00",
        wednesday: "09:00-22:00",
        thursday: "09:00-22:00",
        friday: "09:00-23:00",
        saturday: "10:00-23:00",
        sunday: "10:00-21:00"
      }
    }
  }
)

// 12. Изменить время работы:
db.restaurants.updateOne(
  { restaurant_id: "99999999" },
  {
    $set: {
      "working_hours.sunday": "11:00-20:00",
      "working_hours.friday": "09:00-24:00"
    }
  }
)