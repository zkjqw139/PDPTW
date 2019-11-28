
#pragma once
#include<iostream>
#include<stdio.h>
#include <chrono>
#include <ctime>   
#include <time.h>
#include<vector>
#include<Eigen/Dense>
#include"Route.cuh"
#include<map>
#include"MCTBase.cuh"

namespace MCT {

	std::vector<int>  getRouteinfluenced(std::vector<PDPTW::Route> routePool,std::vector<int> nodeIDs) {

		std::vector<int> routes;

		for (int k = 0; k < nodeIDs.size(); k++) {
			for (int i = 0; i < routePool.size(); i++) {
				if (routePool[i].checkCompany(nodeIDs[k]));
					routes.push_back(i);
			}
		}
		return routes;
	}


	class BoardTest{

	public:

		//输入的Board必须初始化
		BoardTest(MCT::Board board,std::vector<PDPTW::Route> routePool){
			this->board = board;
			this->routePool = routePool;
		}

		void showBoard() {
			board.showBoard();
		}

		void showBoardcondition() {
			int cond = board.getBoardCondition();
			std::cout <<" Board cond is：   "<< cond << std::endl;
		}

		//测试在棋盘上下棋
		void testStepOneMoveOnBoard(int x,int y) {
            
			clock_t start, end;

			start = clock();

			MCT::move oneMove(x, y);
			board.updateBoard(routePool, oneMove, 80);
			std::vector<int> routeInfluenced=getRouteinfluenced(routePool, routePool[x].nodeIDs);
			
			end = clock();
			
			std::cout << "time is: "<<(double)(end - start) / CLOCKS_PER_SEC << std::endl;
			
			//showBoard();
		}

        


	private:
	
		MCT::Board board;
		std::vector<PDPTW::Route> routePool;

	};


	class BusTest {





	};



	class BusPotTest {




	};

}