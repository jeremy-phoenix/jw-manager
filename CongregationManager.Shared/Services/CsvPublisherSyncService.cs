using System;
using System.Collections.Generic;
using System.IO;
using System.Text.RegularExpressions;
using CongregationManager.Data.Components;
using CongregationManager.Data.Models;

namespace CongregationManager.Services;

public static class CsvPublisherSyncService
{
    public record CsvPublisherRecord(
        string FirstName,
        string LastName,
        string? Address,
        List<string> PhoneNumbers,
        bool IsActive
    );

    public record SyncRecordResult(
        Person DbPerson,
        string? OldAddress,
        string? NewAddress,
        List<string> OldPhones,
        List<string> NewPhones,
        bool AddressChanged,
        bool PhonesChanged
    );

    public record SyncResult(
        int Matched,
        int Updated,
        List<SyncRecordResult> Updates,
        List<CsvPublisherRecord> UnmatchedCsv,
        List<Person> UnmatchedDb
    );

    public static List<CsvPublisherRecord> ParseCsvFile(string filePath)
    {
        var records = new List<CsvPublisherRecord>();
        var lines = File.ReadAllLines(filePath);

        if (lines.Length < 4)
            return records;

        var isActive = true;

        for (var i = 3; i < lines.Length; i++)
        {
            var line = lines[i].Trim();
            if (string.IsNullOrWhiteSpace(line))
                continue;

            var columns = ParseCsvLine(line);

            if (
                columns.Count > 1
                && columns[1].Trim().Equals("Inactive", StringComparison.OrdinalIgnoreCase)
            )
            {
                isActive = false;
                continue;
            }

            if (columns.Count < 2 || string.IsNullOrWhiteSpace(columns[1]))
                continue;

            if (!int.TryParse(columns[0].Trim(), out _))
                continue;

            var (lastName, firstName) = ParseName(columns[1]);
            var address = columns.Count > 2 ? NullIfEmpty(columns[2].Trim()) : null;
            var phones = columns.Count > 3 ? ParsePhoneNumbers(columns[3]) : [];

            records.Add(new CsvPublisherRecord(firstName, lastName, address, phones, isActive));
        }

        return records;
    }

    public static (string LastName, string FirstName) ParseName(string raw)
    {
        var parts = raw.Split(',', 2);
        var lastName = parts[0].Trim();
        var firstName = parts.Length > 1 ? parts[1].Trim() : string.Empty;

        firstName = Regex.Replace(firstName, @"\s*\(.*?\)\s*", " ").Trim();

        return (lastName, firstName);
    }

    public static List<string> ParsePhoneNumbers(string? raw)
    {
        if (string.IsNullOrWhiteSpace(raw))
            return [];

        var phones = new List<string>();
        var parts = raw.Split('/');

        foreach (var part in parts)
        {
            var cleaned = Regex.Replace(part, @"\s*\(.*?\)\s*", " ").Trim();
            if (!string.IsNullOrWhiteSpace(cleaned))
                phones.Add(cleaned);
        }

        return phones;
    }

    public static SyncResult SyncRecords(
        List<CsvPublisherRecord> csvRecords,
        List<Person> dbPersons
    )
    {
        var updates = new List<SyncRecordResult>();
        var unmatchedCsv = new List<CsvPublisherRecord>();
        var matchedDbIds = new HashSet<int>();

        var dbLookup = new Dictionary<(string, string), Person>(new NameComparer());

        foreach (var person in dbPersons)
        {
            var key = (person.LastName?.Trim() ?? "", person.FirstName?.Trim() ?? "");
            dbLookup.TryAdd(key, person);
        }

        foreach (var csv in csvRecords)
        {
            var key = (csv.LastName.Trim(), csv.FirstName.Trim());

            if (dbLookup.TryGetValue(key, out var dbPerson))
            {
                matchedDbIds.Add(dbPerson.Id);

                var oldAddress = dbPerson.Address?.Trim();
                var newAddress = csv.Address?.Trim();
                var addressChanged =
                    !string.Equals(oldAddress, newAddress, StringComparison.OrdinalIgnoreCase)
                    && !string.IsNullOrWhiteSpace(newAddress);

                var oldPhones = dbPerson
                    .PhoneNumbers.OrderBy(p => p.Number)
                    .Select(p => p.Number.Trim())
                    .ToList();
                var newPhones = csv.PhoneNumbers.Select(p => p.Trim()).OrderBy(p => p).ToList();
                var phonesChanged =
                    csv.PhoneNumbers.Count > 0
                    && !oldPhones.SequenceEqual(newPhones, StringComparer.OrdinalIgnoreCase);

                if (addressChanged || phonesChanged)
                {
                    updates.Add(
                        new SyncRecordResult(
                            dbPerson,
                            oldAddress,
                            newAddress,
                            oldPhones,
                            csv.PhoneNumbers,
                            addressChanged,
                            phonesChanged
                        )
                    );
                }
            }
            else
            {
                unmatchedCsv.Add(csv);
            }
        }

        var unmatchedDb = dbPersons.Where(p => !matchedDbIds.Contains(p.Id)).ToList();

        return new SyncResult(
            Matched: matchedDbIds.Count,
            Updated: updates.Count,
            Updates: updates,
            UnmatchedCsv: unmatchedCsv,
            UnmatchedDb: unmatchedDb
        );
    }

    public static List<(Person Person, int Score)> FindFuzzyMatches(
        CsvPublisherRecord csv,
        List<Person> candidates,
        int maxResults = 3
    )
    {
        var csvLast = csv.LastName.Trim();
        var csvFirst = csv.FirstName.Trim();
        var scored = new List<(Person Person, int Score)>();

        foreach (var person in candidates)
        {
            var dbLast = person.LastName?.Trim() ?? "";
            var dbFirst = person.FirstName?.Trim() ?? "";
            var score = 0;

            if (string.Equals(dbLast, csvLast, StringComparison.OrdinalIgnoreCase))
                score += 50;
            else if (
                dbLast.Contains(csvLast, StringComparison.OrdinalIgnoreCase)
                || csvLast.Contains(dbLast, StringComparison.OrdinalIgnoreCase)
            )
                score += 30;

            if (string.Equals(dbFirst, csvFirst, StringComparison.OrdinalIgnoreCase))
            {
                score += 50;
            }
            else if (
                dbFirst.StartsWith(csvFirst, StringComparison.OrdinalIgnoreCase)
                || csvFirst.StartsWith(dbFirst, StringComparison.OrdinalIgnoreCase)
            )
            {
                score += 25;
            }
            else if (
                dbFirst.Contains(csvFirst, StringComparison.OrdinalIgnoreCase)
                || csvFirst.Contains(dbFirst, StringComparison.OrdinalIgnoreCase)
            )
            {
                score += 25;
            }

            if (
                !string.IsNullOrWhiteSpace(person.OtherNames)
                && (
                    person.OtherNames.Contains(csvFirst, StringComparison.OrdinalIgnoreCase)
                    || person.OtherNames.Contains(csvLast, StringComparison.OrdinalIgnoreCase)
                )
            )
            {
                score += 15;
            }

            if (score >= 25)
                scored.Add((person, score));
        }

        return scored.OrderByDescending(x => x.Score).Take(maxResults).ToList();
    }

    public static List<PhoneNumber> BuildPhoneNumbers(List<string> phones, int personId)
    {
        var result = new List<PhoneNumber>();
        for (var i = 0; i < phones.Count; i++)
        {
            result.Add(
                new PhoneNumber
                {
                    Number = phones[i],
                    PhoneType = PhoneType.Mobile,
                    IsPrimary = i == 0,
                    PersonId = personId,
                }
            );
        }
        return result;
    }

    private static string? NullIfEmpty(string? value) =>
        string.IsNullOrWhiteSpace(value) ? null : value;

    private static List<string> ParseCsvLine(string line)
    {
        var fields = new List<string>();
        var inQuotes = false;
        var field = new System.Text.StringBuilder();

        for (var i = 0; i < line.Length; i++)
        {
            var c = line[i];
            if (c == '"')
            {
                if (inQuotes && i + 1 < line.Length && line[i + 1] == '"')
                {
                    field.Append('"');
                    i++;
                }
                else
                {
                    inQuotes = !inQuotes;
                }
            }
            else if (c == ',' && !inQuotes)
            {
                fields.Add(field.ToString());
                field.Clear();
            }
            else
            {
                field.Append(c);
            }
        }

        fields.Add(field.ToString());
        return fields;
    }

    private class NameComparer : IEqualityComparer<(string, string)>
    {
        public bool Equals((string, string) x, (string, string) y) =>
            string.Equals(x.Item1.Trim(), y.Item1.Trim(), StringComparison.OrdinalIgnoreCase)
            && string.Equals(x.Item2.Trim(), y.Item2.Trim(), StringComparison.OrdinalIgnoreCase);

        public int GetHashCode((string, string) obj) =>
            HashCode.Combine(
                obj.Item1.Trim().ToUpperInvariant(),
                obj.Item2.Trim().ToUpperInvariant()
            );
    }
}
