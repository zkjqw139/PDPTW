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

	//���øߵ½ӿڻ�ȡʱ�� ������Ϣ
	std::string _getDistanceAndDuration(std::string origin,std::string destination) {
		
		/*
		curl ������������
		1. ����curl_global_init   �õ���ʼ�� libcurl
		2������curl_easy_init()   �����õ�easy interface��ָ��
		3. ����curl_easy_setopt() ���ô�����
		4. ����curl_easy_setopt() ���õĴ���ѡ�ʵ�ֻص�����������û��ض�����
		5. ����curl_easy_perform()������ɴ�������
		6. ����curl_easy_cleanup()�ͷ��ڴ�
		*/

		//curl ��ʼ��
		struct curl_slist *headers = NULL; // init to NULL is important 
	    headers    = curl_slist_append(headers, "Accept: application/json");  
		headers    = curl_slist_append(headers, "Content-Type: application/json");
		headers    = curl_slist_append(headers, "charsets: utf-8");
		CURL *curl = curl_easy_init();
	    
		//�ж�curl
		if (!curl) {
			printf("couldn't init curl ");
			return *DownloadedResponse;
		}
		//��ʼ������
		CURLcode res;

		//query url
		std::string url = "https://restapi.amap.com/v3/distance?";
		url = url + "origins=" + origin + "&" + "destination=" + destination + "&" + "key=36dc0e38d72b81b3d50435d893d23094";

		//ָ��url
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
		int cirDura = mtdDura + dtmDura + 60;  //�������ʱ��Ϊ60s
        

		disInfo dinfo(mtdDist, mtdDura, dtmDist, dtmDura, cirDist, cirDura);

		return dinfo;


	}


	//������빫˾֮��ľ������
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