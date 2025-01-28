const std = @import("std");
const testing = std.testing;

const ctime = @cImport(@cInclude("time.h"));

/// Represents different units of time measurement
pub const TimeUnit = enum {
    /// Represents seconds
    Second,
    /// Represents minutes
    Minute,
    /// Represents hours
    Hour,
    /// Represents days
    Day,
    /// Represents a week
    Week,
    /// Represents months
    Month,
    /// Represents a quarter
    Quarter,
    //// Represents a half year
    Semester,
    /// Represents years
    Year,
    /// Represents decades
    Decade,
    /// Represents centuries
    Century,

    /// Convert the time unit to its string representation
    pub fn toString(self: TimeUnit) []const u8 {
        return switch (self) {
            .Second => "second",
            .Minute => "minute",
            .Hour => "hour",
            .Day => "day",
            .Week => "week",
            .Month => "month",
            .Quarter => "quarter",
            .Semester => "semester",
            .Year => "year",
            .Decade => "decade",
            .Century => "century",
        };
    }    
};

/// Represents a C Date Time
pub const CDateTime = extern struct {
    seconds: c_int,
    minutes: c_int,
    hours: c_int,
    day: c_int,
    month: c_int,
    year: c_int,
    day_of_week: c_int,
    day_of_year: c_int,
    is_day_light_saving: c_int,
};

/// Represents a date and time.
pub const DateTime = extern struct {
    seconds: u8,
    minutes: u8,
    hours: u8,
    day: u8,
    month: u8,
    year: u16,
  };

pub const Date = extern struct {
    day: u8,
    month: u8,
    year: u16,
};

/// Represents a time span.
pub const TimeSpan = extern struct {
    seconds: i32,
    minutes: i32,
    hours: i32,
    day: i32,
    month: i32,
    year: i32,
};

pub const TimeOffset = extern struct {
    amount: i32,
    unit: TimeUnit,
};

export fn isLeapYear(year: u16) bool {
    return (year % 4 == 0 and year % 100 != 0) or year % 400 == 0;
}

export fn calcDayOfYear(year: u16, month: u8, day: u8) u16 {
    const daysInMonth = [_]u8{31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31};

    var dayOfYear: u16 = 0;
    var i: u8 = 0;
    while (i < month - 1) : (i += 1) {
        dayOfYear += daysInMonth[i];
    }

    if (isLeapYear(year) and month > 2) {
        dayOfYear += 1;
    }

    dayOfYear += day;
    return dayOfYear;
}

export fn calcDayOfWeek(year: u16, month: u8, day: u8) u8 {
    const daysInMonth = [12]u8{0, 3, 3, 6, 1, 4, 6, 2, 5, 0, 3, 5};
    const daysInWeek = [7]u8{6, 0, 1, 2, 3, 4, 5};

    const century: u16 = year / 100;
    const yearInCentury: u16 = year % 100;

    const dayOfWeek: u8 = @intCast((yearInCentury + yearInCentury / 4 + daysInMonth[month - 1] + day - 1 + daysInWeek[century % 4]) % 7);
    return dayOfWeek;
}

export fn getLocalCDateTime() CDateTime {
    const now = ctime.time(null);
    const local = ctime.localtime(&now);
    return CDateTime{
        .seconds = local.*.tm_sec,
        .minutes = local.*.tm_min,
        .hours = local.*.tm_hour,
        .day = local.*.tm_mday,
        .month = local.*.tm_mon,
        .year = local.*.tm_year,
        .day_of_week = local.*.tm_wday,
        .day_of_year = local.*.tm_yday,
        .is_day_light_saving = local.*.tm_isdst,
    };
}

pub fn getUtcCDateTime() CDateTime {
    const now = ctime.time(null);
    const utc = ctime.gmtime(&now);
    return DateTime{
        .seconds = utc.*.tm_sec,
        .minutes = utc.*.tm_min,
        .hours = utc.*.tm_hour,
        .day = utc.*.tm_mday,
        .month = utc.*.tm_mon + 1,
        .year = utc.*.tm_year + 1900,
        .day_of_week = utc.*.tm_wday,
        .day_of_year = utc.*.tm_yday,
        .is_day_light_saving = false,
    };
}

pub fn createDateTimeFromCDateTime(cdt: CDateTime) DateTime {
    return DateTime{
        .seconds = @intCast(cdt.seconds),
        .minutes = @intCast(cdt.minutes),
        .hours = @intCast(cdt.hours),
        .day = @intCast(cdt.day),
        .month = @intCast(cdt.month + 1),
        .year = @intCast(cdt.year + 1900),
    };
}

pub fn createDateFromCDateTime(cdt: CDateTime) Date {
    return Date{
        .day = @intCast(cdt.day),
        .month = @intCast(cdt.month + 1),
        .year = @intCast(cdt.year + 1900),
    };
}

export fn createDateTimeFromYmd(year: u16, month: u8, day: u8) DateTime {
    // Check validity of the date
    
    return DateTime{
        .seconds = 0,
        .minutes = 0,
        .hours = 0,
        .day = day,
        .month = month,
        .year = year,
    };
}

export fn createDateTimeFromYmdHms(year: u16, month: u8, day: u8, hours: u8, minutes: u8, seconds: u8) DateTime {
    return DateTime{
        .seconds = seconds,
        .minutes = minutes,
        .hours = hours,
        .day = day,
        .month = month,
        .year = year,
    };
}

export fn createTimeSpanFromYmd(year: i32, month: i32, day: i32) TimeSpan {
    return TimeSpan{
        .seconds = 0,
        .minutes = 0,
        .hours = 0,
        .day = day,
        .month = month,
        .year = year,
    };
}

export fn createTimeSpanFromYmdHms(year: i32, month: i32, day: i32, hours: i32, minutes: i32, seconds: i32) TimeSpan {
    return TimeSpan{
        .seconds = seconds,
        .minutes = minutes,
        .hours = hours,
        .day = day,
        .month = month,
        .year = year,
    };
}   

pub fn createTimeOffset(amount: i32, unit: TimeUnit) TimeOffset {
    return TimeOffset{
        .amount = amount,
        .unit = unit,
    };
}

pub fn createTimeOffsetFromString(definition: []const u8) TimeOffset {
    var amount: i32 = 0;
    var unit: TimeUnit = TimeUnit.Second;

    var i: usize = 0;
    while (i < definition.len) : (i += 1) {
        if (definition[i] >= '0' and definition[i] <= '9') {
            const digit : i32 = @intCast(definition[i] - '0');
            amount = amount * 10 + digit;
        } else {
            unit =
            switch (definition[i]) {
                's'=>  TimeUnit.Second,
                'm'=>  TimeUnit.Minute,
                'h'=>  TimeUnit.Hour,
                'd'=>  TimeUnit.Day,
                'w'=>  TimeUnit.Week,
                'M'=>  TimeUnit.Month,
                'Q'=>  TimeUnit.Quarter,
                'S'=>  TimeUnit.Semester,
                'Y'=>  TimeUnit.Year,
                'D'=>  TimeUnit.Decade,
                'C'=>  TimeUnit.Century,
            };
        }
    }

    return TimeOffset{
        .amount = amount,
        .unit = unit,
    };
}   

/// Converts a digit to a character.
fn digitToChar(digit: u8) u8 {
    return digit + '0';
}

/// Extracts a digit from a number at a given position.
fn extractDigit(number: c_int, position: u8) u8 {
    var res: u8 = 0;
    const unsigned_number : u32 = @intCast(number) ; // Cast to unsigned integer

    switch (position) {
        0 => res = @truncate( @rem(unsigned_number, 10)),
        1 => res = @truncate( @rem(unsigned_number / 10, 10)),
        2 => res = @truncate( @rem(unsigned_number / 100, 10)),
        3 => res = @truncate( @rem(unsigned_number / 1000, 10)),
        else => res =0,
    }
    return res;
}

/// Formats the DateTime struct into a string based on the provided format.
pub fn formatDateTime(dt: DateTime, format: []const u8, allocator: std.mem.Allocator) ![]u8 {

    const months = "JanFebMarAprMayJunJulAugSepOctNovDec";
    const days3 = "SunMonTueWedThuFriSat";
    
    const buffer = try allocator.alloc(u8, format.len);

    var i: usize = 0;
    var j: usize = 0;
    while (i < format.len) : (i += 1) {
        if (format[i] == 'y' and i + 3 < format.len and format[i + 1] == 'y' and format[i + 2] == 'y' and format[i + 3] == 'y') {
            buffer[j] = digitToChar(extractDigit(dt.year, 3));
            buffer[j + 1] = digitToChar(extractDigit(dt.year, 2));
            buffer[j + 2] = digitToChar(extractDigit(dt.year, 1));
            buffer[j + 3] = digitToChar(extractDigit(dt.year, 0));
            j += 4;
            i += 3;
        } else if (format[i] == 'y' and i + 1 < format.len and format[i + 1] == 'y') {
            buffer[j] = digitToChar(extractDigit(dt.year, 1));
            buffer[j + 1] = digitToChar(extractDigit(dt.year, 0));
            j += 2;
            i += 1;
        } else if (format[i] == 'M' and i + 2 < format.len and format[i + 1] == 'M' and format[i + 2] == 'M') {            
            const offset : u8 = @intCast((dt.month - 1) * 3) ; // Cast to unsigned integer
            buffer[j] = months[offset];
            buffer[j + 1] = months[offset + 1];
            buffer[j + 2] = months[offset + 2];
            j += 3;
            i += 2;
        } else if (format[i] == 'M' and i + 1 < format.len and format[i + 1] == 'M') {
            buffer[j] = digitToChar(extractDigit(dt.month, 1));
            buffer[j + 1] = digitToChar(extractDigit(dt.month, 0));
            j += 2;
            i += 1;
        } 
        else if (format[i] == 'd' and i + 2 < format.len and format[i + 1] == 'd' and format[i + 2] == 'd') {
            const day_of_week: u8 = calcDayOfWeek(dt.year, dt.month, dt.day);
            const offset : u8 = @intCast(day_of_week * 3) ; // Cast to unsigned integer

            buffer[j] = days3[offset];
            buffer[j + 1] = days3[offset + 1];
            buffer[j + 2] = days3[offset + 2];
            j += 3;
            i += 2;
        }
        else if (format[i] == 'd' and i + 1 < format.len and format[i + 1] == 'd') {
            buffer[j] = digitToChar(extractDigit(dt.day, 1));
            buffer[j + 1] = digitToChar(extractDigit(dt.day, 0));
            j += 2;
            i += 1;
        } 
        else if (format[i] == 'h' and i + 1 < format.len and format[i + 1] == 'h') {
            buffer[j] = digitToChar(extractDigit(dt.hours, 1));
            buffer[j + 1] = digitToChar(extractDigit(dt.hours, 0));
            j += 2;
            i += 1;
        } else if (format[i] == 'm' and i + 1 < format.len and format[i + 1] == 'm') {
            buffer[j] = digitToChar(extractDigit(dt.minutes, 1));
            buffer[j + 1] = digitToChar(extractDigit(dt.minutes, 0));
            j += 2;
            i += 1;
        } else if (format[i] == 's' and i + 1 < format.len and format[i + 1] == 's') {
            buffer[j] = digitToChar(extractDigit(dt.seconds, 1));
            buffer[j + 1] = digitToChar(extractDigit(dt.seconds, 0));
            j += 2;
            i += 1;
        } else {
            buffer[j] = format[i];
            j += 1;
        }
    }

    return buffer; 
}

/// Check if a number exists in an array
fn contains(comptime T: type, haystack: []const T, needle: T) bool {
    for (haystack) |item| {
        if (item == needle) return true;
    }
    return false;
}

test "isLeapYear" {
    // Leap year from 1900 to 2100
    const leapYears = [49]u16{
        1904, 1908, 1912, 1916, 1920, 1924, 1928, 1932, 1936, 1940, 1944, 1948, 1952, 1956, 1960, 1964, 1968, 1972, 1976, 1980, 1984, 1988, 1992, 1996, 2000, 2004, 2008, 2012, 2016, 2020, 2024, 2028, 2032, 2036, 2040, 2044, 2048, 2052, 2056, 2060, 2064, 2068, 2072, 2076, 2080, 2084, 2088, 2092, 2096,
    };

    // Check couple of years
    try testing.expect(contains(u16, &leapYears, 2000));
    try testing.expect(!contains(u16, &leapYears, 2001));

    // Loop over all dates from 1900 to 2100
    var year: u16 = 1900;
    while (year < 2100) : (year += 1) {
        if (contains(u16, &leapYears, year)) {
            try testing.expect(isLeapYear(year));
        } else {
            try testing.expect(!isLeapYear(year));
        }
    }
}

test "getLocalTime" {
    const dt = getLocalCDateTime();

    // Basic assertions to ensure the values are within expected ranges
    try std.testing.expect(dt.seconds >= 0 and dt.seconds < 60);
    try std.testing.expect(dt.minutes >= 0 and dt.minutes < 60);
    try std.testing.expect(dt.hours >= 0 and dt.hours < 24);
    try std.testing.expect(dt.day >= 1 and dt.day <= 31);
    try std.testing.expect(dt.month >= 0 and dt.month < 12);
    try std.testing.expect(dt.year >= 70); // Since tm_year is years since 1900
    try std.testing.expect(dt.day_of_week >= 0 and dt.day_of_week < 7);
    try std.testing.expect(dt.day_of_year >= 0 and dt.day_of_year < 366);
}

test "formatDateTime" {
     var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
     defer arena.deinit();
  
    const cdt = getLocalCDateTime();
    const dt = createDateTimeFromCDateTime(cdt);
    const formatted = try formatDateTime(dt, "yyyy MMM ddd hh:mm:ss", arena.allocator());             

    std.debug.print("{s}", .{formatted});
}

