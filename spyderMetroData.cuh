#pragma  once
#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include <iostream>
#include <stdio.h>
#include <cuda.h>
#include "loadData.h"
#include "stdlib.h"
#include "process.h"

namespace PDPTW {


	__host__ void spyder(std::string metro_station_name, std::string hour_begin, std::string hour_end, std::string day_begin, std::string day_end) {
           
		FILE *fp;
		char  buf[255] = { 0 };

		std::string shellcmd = "activate torch & python E:/torch/metro/getMetroData -metro_station_name   "  + metro_station_name + "  " + "-hours" + "  " + hour_begin + "  " + hour_end + "   " + "-trade_date" + "   " + day_begin + "   " + day_end;
	 

		const char * c = shellcmd.c_str();
		printf("%s\n", c);

		if ((fp = _popen(c, "r")) == NULL) {
			perror("Fail to popen\n");
			exit(1);
		}
		while (fgets(buf, 255, fp) != NULL) {
			printf("%s", buf);
		}
		_pclose(fp);
	}

	__host__ map<string, int> loadMetroData(std::string filename) {

		cout << "load dataframe from  " << filename << endl;
		std::ifstream is(filename);

		std::string timeid;
		std::string index;
		std::string line;

		std::getline(is, line);
		
		map<string, int>  metrocondition;

		while (std::getline(is, index, ',')) {
			
			cout << "index: " << index << " ";
			std::getline(is, timeid, ',');
			cout << "time_id: " << timeid << " ";
			std::getline(is, line);
			cout << "flownum: " << atoi(line.c_str())<<endl;
			metrocondition.insert(std::pair<std::string,int>(timeid, atoi(line.c_str())));
			 
		}
		return metrocondition;
	}
	
	__host__ std::map<int, float>  metroFlowDistribution() {

		map<string, int>  metrocondition = loadMetroData("E:/torch/metro/'西兴站'出站每时刻客流.csv");
		std::map<string, int>::iterator it = metrocondition.begin();

		int totalnum = 0;

		std::map<int, float> flowPercent;

		for (it = metrocondition.begin(); it != metrocondition.end(); it++) {
			
			int hour   = int(it->first[0]-'0')*10+int(it->first[1]-'0');
			if (hour == 8) {
				totalnum = totalnum + it->second;
			}
		}

		for (it = metrocondition.begin(); it != metrocondition.end(); it++) {

			int hour = int(it->first[0] - '0') * 10 + int(it->first[1] - '0');

			int timeid = 0;
			for (int i = 3; i < it->first.size(); i++) {
				timeid = timeid * 10 + int(it->first[i] - '0');
			}


			if (hour == 8) {
				float percent = float(it->second) / float(totalnum);
				cout << percent << endl;
				flowPercent.insert(std::pair<int, float>(timeid, percent));
			}

		}
	    
		/*
		std::map<int, float>::iterator _it = flowPercent.begin();
		for (_it = flowPercent.begin(); _it != flowPercent.end(); _it++) {

			cout << _it->first << " " << _it->second << endl;
		}*/


		return flowPercent;

	}

	




}