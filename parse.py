import subprocess

def valid(number):
  for x in number:
    if x < '0' or x > '9':
      return False
  return True

def parseLine(line):
  number = line.split('\t')[0]
  if valid(number):
    return int(number)
  return 0

def main():
  with open("log.csv") as file:
    codeCount = 0
    newLine = ""
    flag = True

    for line in file:
      if line == '\n':
        flag = True
        result = newLine.split('\n')[0] + str(codeCount)
        print(result)
        codeCount = 0;
        newLine = ""
        continue

      if flag is True:
        newLine = line
        flag = False
      else:
        codeCount += parseLine(line)

if __name__=="__main__":
    main()

