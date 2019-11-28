#pragma once
#include "device_launch_parameters.h"
#include <cuda_runtime.h>
#include<stdio.h>
#include<iostream>
#include<fstream>
#include<cstringt.h>
#include<string>
#include"../PDPTW/User.cuh"


/*
对于云接驳可以考虑为一个CVRP的问题，
不用考虑用户的时间窗口，
对于货物来说则所有物体目标都是从场站出发，
最后到达线路上任何终点都为目标的终点，
所以导入数据时候会比较简单

导入时会把所有用户导入到一个用户池子，
并且计算所有用户到达其它用户的最短距离，时间
代价函数目标为最小化运行距离和最大化用户满意度
*/


namespace PDPTW {

	//读取数据格式为
	__host__ UserGroup* loadUserData(UserGroup* users,size_t* size) {
	 
			int flag = 1;
			std::string keyword;
			std::string dot;

			//读写文件名称
			std::string ReadFileName;
			std::string line;
			std::ifstream is("C:/Users/hasee/Documents/Visual Studio 2015/Projects/PDPTW/DataSrc/A-VRP/A-n36-k5.vrp");
			std::getline(is, line);
			printf("start read route file\n");
			std::cout << line << std::endl;

			//读取文章建议
			std::getline(is, line);
			std::cout << line << std::endl;

			//读取问题类型
		 
			std::getline(is, line);
			std::cout << line << std::endl;
			//printf("%s : %s\n", keyword, ProblemType);

			//读取节点数目
			int  num;
			std::getline(is, line);
			char *cstr2 = new char[line.length() + 1];
			strcpy(cstr2, line.c_str());

			char *token2;
			token2 = strtok(cstr2, " : ");
			int count2 = 0;
			while (token2 != NULL) {
 

				switch (count2) {
				case(0):
					std::cout << token2;
					break;
				case(1):
					num = atoi(token2);
					std::cout <<"  "<< num << std::endl;
					break;

				default:
					break;
				}
				count2 = count2 + 1;
				token2 = strtok(NULL, " : ");
			}
			 
			//printf("%s : %d\n", keyword, num);


			//读取权重类型 
			std::getline(is, line);
			std::cout << line << std::endl;
			//printf("%s : %s\n", keyword, EdgeWeightType);

			//读取车容量
			int capcity;
			std::getline(is, line);
			char *cstr3= new char[line.length() + 1];
			strcpy(cstr3, line.c_str());

			char *token3;
			token3 = strtok(cstr3, " : ");
			int count3 = 0;
			while (token3 != NULL) {


				switch (count3) {
				case(0):
					std::cout << token3;
					break;
				case(1):
					capcity = atoi(token3);
					std::cout << "  " << capcity << std::endl;
					break;

				default:
					break;
				}
				count3 = count3 + 1;
				token3 = strtok(NULL, " : ");
			}
			 

			//读取关键字
		 
			std::getline(is, line);
			std::cout << line << std::endl;
			 
			users=(UserGroup* )malloc(num * sizeof(UserGroup));
			*size = num;

			for (int i = 0; i < num; i++) {

				int stationID;
				int lon;
				int lat;

				std::getline(is, line);
				 
				char *cstr4 = new char[line.length() + 1];
				strcpy(cstr4, line.c_str());

				char *token4;
				token4 = strtok(cstr4, " ");
				int count4 = 0;
				while (token4 != NULL) {


					switch (count4) {
					case(0):
						stationID=atoi(token4);
						std::cout << "  " << stationID;
						break;
					case(1):
						lon = atoi(token4);
						std::cout << "  " << lon;
						break;
					case(2):
						lat = atoi(token4);
						std::cout << "  " << lat << std::endl;
						break;

					default:
						break;
					}
					count4 = count4 + 1;
					token4 = strtok(NULL, " ");
				}
				

				users[i].groupID           = stationID;
				users[i].UserUpStationID   = stationID;
				users[i].UserDownStationID = 1;
				users[i].UserUpStationLon  = (float)lon;
				users[i].UserUpStationLat  = (float)lat;
				
			}

			//读取关键字
			std::getline(is, line);
			std::cout << line << std::endl;
			 

			for (int i = 0; i < num; i++) {

				int _stationID;
				int _count;
				

				std::getline(is, line);
				char *cstr5 = new char[line.length() + 1];
				strcpy(cstr5, line.c_str());

				char *token5;
				token5 = strtok(cstr5, " ");
				int count5 = 0;
				while (token5 != NULL) {


					switch (count5) {
					case(0):
						_stationID = atoi(token5);
						std::cout << "  " << _stationID;
						break;
					case(1):
						_count = atoi(token5);
						users[i].userCount = _count;
						std::cout << "  " << _count << std::endl;
						break;
			 
					default:
						break;
					}
					count5 = count5 + 1;
					token5 = strtok(NULL, " ");
				}

			
				
			}
		 
 

			return users;
			 
	}


	__host__ float* caldistMatirx(PDPTW::UserGroup *users,size_t* size,float* DistMatrix) {

		int lenth = *size;
		for (int i = 0; i < *size; i++) {
			for (int j = 0; j < *size; j++) {

				if (i == j) {
					DistMatrix[i*lenth + j] = 0;
				}
				else {
					DistMatrix[i*lenth + j] = sqrt(float(users[i].UserUpStationLon - users[j].UserUpStationLon)*float(users[i].UserUpStationLon - users[j].UserUpStationLon) + \
												   float(users[i].UserUpStationLat - users[j].UserUpStationLat)*float(users[i].UserUpStationLat - users[j].UserUpStationLat));
				}
			}
		}

		return DistMatrix;
	}

	
}


