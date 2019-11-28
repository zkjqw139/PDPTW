#include<iostream>
#include<fstream>
#include<string.h>
#include<string>
#include"Company.cuh"
#include<vector>

using namespace std;


namespace PDPTW {

	vector<PDPTW::company> loadDF(std::string filename) {

		cout << "load dataframe from  " << filename << endl;
		std::ifstream is(filename);

		std::string line;
		std::getline(is, line);

		vector<PDPTW::company> companys;

		while (std::getline(is,line)) {
			
		    //load csv data to comapany

			std::string name;
			float lon;
			float lat;
			int   employeeNum;
			int   employeeDemand;
			float stationLon;
			float stationLat;
			
	 
			char *cstr = new char[line.length() + 1];
			strcpy(cstr, line.c_str());
			 
			char *token;
			token = strtok(cstr, ",");
            
			int count = 0;
			while (token != NULL) {
				
				switch (count) {
					case(0):
						 
						name.assign(token, strlen(token));

						break;
					case(1):
						lon = atof(token);
						break;
					case(2):
						lat = atof(token);
						break;
					case(3):
						employeeNum = atoi(token);
						break;
					case(4):
						employeeDemand = atoi(token);
						break;
					case(5):
						stationLon = atof(token);
						break;
					case(6):
						stationLat = atof(token);
						break;
					default:
						break;
				}
				count = count + 1;
				token = strtok(NULL, ",");
			}

			PDPTW::company acompany(name, lon, lat, employeeNum, employeeDemand);
			companys.push_back(acompany);

			delete[] cstr;


			//cout << name << "  " << lon << "  " << lat << "  " << employeeNum << "  " << employeeDemand << endl;
			//printf("\n");
	
		}

		return companys;
	}

}