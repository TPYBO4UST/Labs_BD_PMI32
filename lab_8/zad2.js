// 1. Разница между максимальной и минимальной температурой
db.weather.aggregate([
  {
    $group: {
      _id: null,
      maxTemp: { $max: "$temperature" },
      minTemp: { $min: "$temperature" }
    }
  },
  {
    $project: {
      _id: 0,
      difference: { $subtract: ["$maxTemp", "$minTemp"] }
    }
  }
])

// 2. Средняя температура без 10 самых низких и высоких:
db.weather.aggregate([
  { $sort: { temperature: 1 } },
  {
    $group: {
      _id: null,
      temps: { $push: "$temperature" }
    }
  },
  {
    $project: {
      _id: 0,
      avgTemp: {
        $avg: {
          $slice: [
            "$temps",
            10,
            { $subtract: [{ $size: "$temps" }, 20] }
          ]
        }
      }
    }
  }
])

// 3. 10 самых холодных дней с южным ветром:
db.weather.aggregate([
  { $match: { wind_direction: "Южный" } },
  { $sort: { temperature: 1 } },
  { $limit: 10 },
  {
    $group: {
      _id: null,
      avgTemp: { $avg: "$temperature" },
      records: { $push: "$$ROOT" }
    }
  }
])

// 4. Дни со снегом (температура < 0 и code = "SN"):
db.weather.aggregate([
  { 
    $match: { 
      temperature: { $lt: 0 },
      code: "SN"
    } 
  },
  {
    $group: {
      _id: {
        year: "$year",
        month: "$month",
        day: "$day"
      }
    }
  },
  { $count: "snow_days" }
])

// 5. Разница между снегом и дождем зимой:
db.weather.aggregate([
  { $match: { month: { $in: [12, 1, 2] } } },
  {
    $group: {
      _id: "$code",
      count: { $sum: 1 }
    }
  },
  { $sort: { _id: 1 } }
])

//6. Вероятность осадков в ясный день:
db.weather.aggregate([
  {
    $group: {
      _id: {
        year: "$year",
        month: "$month",
        day: "$day"
      },
      clear_count: {
        $sum: { $cond: [{ $eq: ["$code", "CL"] }, 1, 0] }
      },
      total_measurements: { $sum: 1 },
      has_precipitation: {
        $max: { $cond: [{ $ne: ["$code", "CL"] }, 1, 0] }
      }
    }
  },
  {
    $match: {
      $expr: {
        $gt: [
          { $divide: ["$clear_count", "$total_measurements"] },
          0.75
        ]
      }
    }
  },
  {
    $group: {
      _id: null,
      total_clear_days: { $sum: 1 },
      precipitation_days: { $sum: "$has_precipitation" }
    }
  },
  {
    $project: {
      _id: 0,
      probability: {
        $multiply: [
          { $divide: ["$precipitation_days", "$total_clear_days"] },
          100
        ]
      }
    }
  }
])

// 7. Изменение температуры в нечетные дни зимы:
db.weather.aggregate([
  { 
    $match: { 
      month: { $in: [12, 1, 2] },
      day: { $mod: [2, 1] } // нечетные дни
    }
  },
  {
    $group: {
      _id: null,
      avgTempOriginal: { $avg: "$temperature" },
      count: { $sum: 1 }
    }
  },
  {
    $project: {
      _id: 0,
      avgTempOriginal: 1,
      avgTempIncreased: { $add: ["$avgTempOriginal", 1] },
      change: 1
    }
  }
])