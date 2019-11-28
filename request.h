#pragma once
#include "curl/curl.h"
#include "cjson\cJSON.h"
#include <iostream>
#include <stdio.h>



namespace PDPTW {

	static std::string *DownloadedResponse;
	static int writer(char*data, size_t size, size_t nmemb, std::string* buffer_in) {
		// Is there anything in buffer?
		if (buffer_in != NULL) {

			buffer_in->clear();
			//append the data to the buffer
			buffer_in->append(data, size* nmemb);

			//How much did we write?
			DownloadedResponse = buffer_in;

			return size* nmemb;
		}
		return 0;
	}

	//调用高德接口获取时间 距离信息
	std::string _getDistanceAndDuration(std::string origin,std::string destination) {
		
		/*
		curl 传输任务流程
		1. 调用curl_global_init   得到初始化 libcurl
		2，调用curl_easy_init()   函数得到easy interface型指针
		3. 调用curl_easy_setopt() 设置传输项
		4. 根据curl_easy_setopt() 设置的传输选项，实现回调函数以完成用户特定任务‘
		5. 调用curl_easy_perform()函数完成传输任务
		6. 调用curl_easy_cleanup()释放内存
		*/

		//curl 初始化
		struct curl_slist *headers = NULL; // init to NULL is important 
	    headers    = curl_slist_append(headers, "Accept: application/json");  
		headers    = curl_slist_append(headers, "Content-Type: application/json");
		headers    = curl_slist_append(headers, "charsets: utf-8");
		CURL *curl = curl_easy_init();
	    
		//判断curl
		if (!curl) {
			printf("couldn't init curl ");
			return *DownloadedResponse;
		}
		//初始化参数
		CURLcode res;

		//query url
		std::string url = "https://restapi.amap.com/v3/distance?";
		url = url + "origins=" + origin + "&" + "destination=" + destination + "&" + "key=36dc0e38d72b81b3d50435d893d23094";

		//指定url
		curl_easy_setopt(curl, CURLOPT_URL, url.c_str());
		curl_easy_setopt(curl, CURLOPT_HTTPGET,1);
		curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, writer);
		res = curl_easy_perform(curl);

		char*ct;
		res = curl_easy_getinfo(curl, CURLINFO_CONTENT_TYPE, &ct);
		if ((CURLE_OK == res) && ct) {
			return * DownloadedResponse;
		}

		curl_slist_free_all(headers);
		curl_easy_cleanup(curl);
		return *DownloadedResponse;
	}
     

	struct disInfo {

		int metroToDestDistance;
		int metroToDestDuration;
		int destToMetroDistance;
		int destToMetroDuration;
		int circleDistance;
		int circleDuration;

		disInfo(int mtdDist,int mtdDura,int dtmDist,int dtmDura,int cirDist,int cirDura) {
			
			this->metroToDestDistance = mtdDist;
			this->metroToDestDuration = mtdDura;
			this->destToMetroDistance = dtmDist;
			this->destToMetroDuration = dtmDura;
			this->circleDistance      = cirDist;
			this->circleDuration      = cirDura;
		}

	};

	struct singleInfo {

		int dist;
		int duration;

	};

	singleInfo  getDistanceAndDuration(std::string origin, std::string destination) {

	 
		std::string RES = _getDistanceAndDuration(origin, destination);
		cJSON * root = cJSON_Parse(RES.c_str());
		cJSON * result = cJSON_GetObjectItem(root, "results");


		int distance = 0;
		int duration = 0;

		for (int i = 0; i < cJSON_GetArraySize(result); i++) {

			cJSON* subitem = cJSON_GetArrayItem(result, i);
			distance = atoi(cJSON_GetObjectItem(subitem, "distance")->valuestring);
			duration = atoi(cJSON_GetObjectItem(subitem, "duration")->valuestring);
		}
		
		singleInfo sinfo;
		sinfo.dist = distance;
		sinfo.duration = duration;

		return sinfo;

	}

	disInfo  getAllDistanceAndDuration(std::string origin, std::string destination) {

		singleInfo sinfo = getDistanceAndDuration(origin, destination);
		singleInfo sinfo2 = getDistanceAndDuration(destination, origin);

		int mtdDist = sinfo.dist;
		int mtdDura = sinfo.duration;
		int dtmDist = sinfo2.dist;
		int dtmDura = sinfo2.duration;
		int cirDist = mtdDist + dtmDist;
		int cirDura = mtdDura + dtmDura + 60;  //假设服务时间为60s
        

		disInfo dinfo(mtdDist, mtdDura, dtmDist, dtmDura, cirDist, cirDura);

		return dinfo;


	}


	//获得输入公司之间的距离矩阵
	__host__  void getDistMatrix(float * DistMatrix, float * DurationMatrix,std::vector<PDPTW::CompanyWithTimeTable> companys) {

		size_t size = companys.size();

		for (int i = 0; i < size; i++) { 
			for (int j = 0; j < size; j++) {
				
				printf("process %d total is %d",i*size+j,size*size);
				printf("\r");

				if (i == j) {
					DistMatrix[i*size + j] = 0;
					DurationMatrix[i*size + j] = 0;
					continue;
				}
				else {
					  
					std::string origin = std::to_string(companys[i].lon) + "," + std::to_string(companys[i].lat);
					std::string destination = std::to_string(companys[j].lon) + "," + std::to_string(companys[j].lat);
					 
					disInfo dinfo= getAllDistanceAndDuration(origin, destination);
					DistMatrix[i*size + j] = dinfo.destToMetroDistance;
					DurationMatrix[i*size + j] = dinfo.destToMetroDuration;
				}
			}
		}
		printf("\n");
	}

 

}