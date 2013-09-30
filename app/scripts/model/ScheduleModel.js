(function() {
  define(["underscore", "momentjs"], function(_, Moment) {
    var ScheduleModel;
    return ScheduleModel = (function() {
      ScheduleModel.prototype.rules = {
        evening: 18,
        laterTodayDelay: 3,
        startOfWeek: 1,
        startOfWeekend: 6,
        weekday: {
          start: "Monday",
          morning: 9
        },
        weekend: {
          start: "Saturday",
          morning: 10
        }
      };

      function ScheduleModel(settings) {
        this.settings = settings;
        this.validateSettings();
        this.data = this.getData();
      }

      ScheduleModel.prototype.validateSettings = function() {};

      ScheduleModel.prototype.getData = function() {
        return [
          {
            id: "later today",
            title: this.getDynamicTime("Later Today"),
            disabled: false
          }, {
            id: "this evening",
            title: this.getDynamicTime("This Evening"),
            disabled: false
          }, {
            id: "tomorrow",
            title: this.getDynamicTime("Tomorrow"),
            disabled: false
          }, {
            id: "day after tomorrow",
            title: this.getDynamicTime("Day After Tomorrow"),
            disabled: false
          }, {
            id: "this weekend",
            title: this.getDynamicTime("This Weekend"),
            disabled: false
          }, {
            id: "next week",
            title: this.getDynamicTime("Next Week"),
            disabled: false
          }, {
            id: "unspecified",
            title: this.getDynamicTime("Unspecified"),
            disabled: false
          }, {
            id: "at location",
            title: this.getDynamicTime("At Location"),
            disabled: true
          }, {
            id: "pick a date",
            title: this.getDynamicTime("Pick A Date"),
            disabled: false
          }
        ];
      };

      ScheduleModel.prototype.getDateFromScheduleOption = function(option, now) {
        var newDate;
        if (now) {
          newDate = moment(now);
        } else {
          newDate = moment();
        }
        switch (option) {
          case "later today":
            newDate.hour(newDate.hour() + this.rules.laterTodayDelay);
            break;
          case "this evening":
            if (newDate.hour() >= this.rules.evening) {
              newDate.add("days", 1);
            }
            newDate.hour(this.rules.evening);
            newDate = newDate.startOf("hour");
            break;
          case "tomorrow":
            newDate.add("days", 1);
            newDate.hour(this.rules.weekday.morning);
            newDate = newDate.startOf("hour");
            break;
          case "day after tomorrow":
            newDate.add("days", 2);
            newDate.hour(this.rules.weekday.morning);
            newDate = newDate.startOf("hour");
            break;
          case "this weekend":
            if (newDate.day() === this.rules.startOfWeekend) {
              newDate.add("days", 7);
            } else {
              newDate.day(this.rules.weekend.start);
            }
            newDate.hour(this.rules.weekend.morning);
            newDate = newDate.startOf("hour");
            break;
          case "next week":
            if (newDate.day() === this.rules.startOfWeek) {
              newDate.add("days", 7);
            } else {
              newDate.day(this.rules.weekday.start);
            }
            newDate.hour(this.rules.weekday.morning);
            newDate = newDate.startOf("hour");
            break;
          default:
            return null;
        }
        return newDate.toDate();
      };

      ScheduleModel.prototype.getDynamicTime = function(time, now) {
        var dayAfterTomorrow;
        if (!now) {
          now = moment();
        }
        switch (time) {
          case "This Evening":
            if (now.hour() >= 18) {
              return "Tomorrow Evening";
            } else {
              return "This Evening";
            }
          case "Day After Tomorrow":
            dayAfterTomorrow = moment(now).add("days", 2);
            return dayAfterTomorrow.format("dddd");
          case "This Weekend":
            if (now.day() < 5) {
              return "This Weekend";
            } else {
              return "Next Weekend";
            }
          default:
            return time;
        }
      };

      ScheduleModel.prototype.toJSON = function() {
        return {
          options: this.data
        };
      };

      return ScheduleModel;

    })();
  });

}).call(this);
