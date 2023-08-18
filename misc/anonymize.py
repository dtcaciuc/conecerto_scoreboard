"""
Anonymize the contents of driverData.csv.

Usage: python3 anonymize.py path/to/input.csv > output.csv

"""
import csv
import names
import sys


def main():
    with open(sys.argv[1], 'r') as f:
        rd = csv.DictReader(f)

        wr = csv.DictWriter(sys.stdout, fieldnames=rd.fieldnames)
        wr.writeheader()

        for i, rec in enumerate(rd):
            gender = 'female' if 'Ladies' in rec['XGroup'] else 'male'
            rec["First Name"] = names.get_first_name(gender=gender)
            rec["Last Name"] = names.get_last_name()
            rec["Number"] = i + 1
            rec["Barcode"] = "{:06}".format(i + 1)
            rec["Sponsor"] = ""

            wr.writerow(rec)


if __name__ == "__main__":
    main()
