/*Design your own linked list class to hold a series of integers. 
The class should have member functions for appending, inserting, and 
deleting nodes. Don’t forget to add a destructor that destroys the list. 
Demonstrate the class with a driver program.*/

#include <iostream>
using namespace std;

struct List 
{
	float val; 
	List *next;
};

List *head;

class LinkedList
 {
	public:
	int insertNode(float num);
	int appendNode(float num);
	void deleteNode(float num);
	void destroyList();
	void displayList();
	~LinkedList() 
	{
		destroyList();
	}
};

int LinkedList::appendNode(float num)
{
}
