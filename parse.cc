#include <iostream>
#include <string>
#include <fstream>

using namespace std;

enum class state { kHeader, kBody, kOut };

static bool isValid (const string &s) {
  for (const char &ch : s) {
    if (ch < '0' || ch > '9') {
      return false;
    }
  }
  return true;
}

static uint32_t parseLine(const string &str) {
  if (str.empty()) {
    return 0;
  }
  uint32_t i = 0;
  uint32_t n = str.size();
  while (i < n && (str[i] != ' ' && str[i] != '\t')) {
    ++i;
  }

  if (i == n) {
    return 0;
  }

  string number = str.substr(0, i);
  if (isValid(number)) {
    return stoi(number);
  } else {
    return 0;
  }
}

int main(int argc, char **argv) {
  if (argc != 3) {
    cerr << "Files are not specified " << endl;
    return 1;
  }
  string iFilename = argv[1];
  string oFilename = argv[2];

  string line;
  ifstream iFile(iFilename);
  ofstream oFile(oFilename);
  if (!oFile.is_open()) {
    cerr << "Unable to open the file " << oFilename << endl;
    return 1;
  }

  state st = state::kHeader;

  if (iFile.is_open()) {
    string newLine;
    uint32_t codeAdded = 0;
    while (getline(iFile, line)) {
      if (line.empty()) {
        newLine = newLine + to_string(codeAdded) + '\n';
        oFile << newLine;
        newLine.clear();
        codeAdded = 0;
        st = state::kHeader;
        continue;
      }
      if (st == state::kHeader) {
        newLine = line;
        st = state::kBody;
      } else if (st == state::kBody) {
        codeAdded += parseLine(line);
      } else {
        cerr << "Invalid state " << endl;
        return 1;
      }
    }
    iFile.close();
    oFile.close();
  } else {
    cerr << "Unable to open file" << endl;
    return 1;
  }

  return 0;
}
