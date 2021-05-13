#include <occi.h>
#include <iostream>

using oracle::occi::Environment;
using oracle::occi::Connection;
using namespace oracle::occi;
using namespace std;

struct ShoppingCart
{
	int product_id {0};
	double price {0};
	int quantity {0};
};

//The customer can purchase up to five items in one order.
const int MAX_CART_SIZE = 5;

int mainMenu();
int customerLogin(Connection* conn, int customerId);
int addToCart(Connection* conn, struct ShoppingCart cart[]);
double findProduct(Connection* conn, int product_id);
void displayProducts(struct ShoppingCart cart[], int productCount);
int checkout(Connection* conn, struct ShoppingCart cart[], int customerId, int productCount);

int main()
{
	// OCCI Variables
	Environment* env = nullptr;
	Connection* conn = nullptr;

	// Used Variables
	string str;
	string user = "dbs311_211f16";
	string pass = "13306282";
	string constr = "myoracle12c.senecacollege.ca:1521/oracle12c";

	try
	{
		env = Environment::createEnvironment(Environment::DEFAULT);
		conn = env->createConnection(user, pass, constr);
		cout << "Connection is Successful!" << endl;
		Statement* stmt = conn->createStatement();
	
		stmt->execute("CREATE OR REPLACE PROCEDURE find_customer (p_customer_id IN NUMBER, found OUT NUMBER) IS"
			" v_custid NUMBER;"
			" BEGIN"
			" found:=1;"
			" SELECT customer_id"
			" INTO v_custid"
			" FROM customers"
			" WHERE customer_id=p_customer_id;"
			" EXCEPTION"
			" WHEN NO_DATA_FOUND THEN"
			" found:=0;"
			" END;"
		);

		stmt->execute("CREATE OR REPLACE PROCEDURE find_product(p_product_id IN NUMBER, price OUT products.list_price%TYPE) IS"
			" BEGIN"
			" SELECT list_price INTO price"
			" FROM products"
			" WHERE product_id=p_product_id;"
			" EXCEPTION"
			" WHEN NO_DATA_FOUND THEN"
			" price:=0;"
			" END;"
		);

		stmt->execute("CREATE OR REPLACE PROCEDURE add_order(p_customer_id IN NUMBER, new_order_id OUT NUMBER) IS"
			" BEGIN"
			" SELECT MAX(order_id) INTO new_order_id"
			" FROM orders;"
			" new_order_id:=new_order_id+1;"
			" INSERT INTO orders"
			" VALUES(new_order_id, p_customer_id, 'Shipped', 56, sysdate);"
			" END;"
		);

		stmt->execute("CREATE OR REPLACE PROCEDURE"
			" add_order_item(orderId IN order_items.order_id % type,"
			" itemId IN order_items.item_id % type,"
			" productId IN order_items.product_id % type,"
			" quantity IN order_items.quantity % type,"
			" price IN order_items.unit_price % type)"
			" IS"
			" BEGIN"
			" INSERT INTO order_items"
			" VALUES(orderId, itemId, productId, quantity, price);"
			" END;"
		);

		ShoppingCart cart[MAX_CART_SIZE];
		int option = 0, id = 0, exists = 0, count = 0;

		do
		{
			option = mainMenu();
			switch (option)
			{
				case 1:
					//request user to enter the customer ID
					cout << "Enter the customer ID: ";
					cin >> id;

					//if the customer ID exists
					exists = customerLogin(conn, id);
					if (exists)
					{
						//call the findProduct() function to check if the product ID exists
						count = addToCart(conn, cart);

						//Display the product’s price to the user and ask the user to enter the quantity.
						displayProducts(cart, count);

						checkout(conn, cart, id, count);
					}
					else
					{
						//if the customer ID does not exists
						cout << "The customer does not exist." << endl;
					}
					break;

				case 0:
					cout << "Good bye!..." << endl;
				return 0;
			}
		} while (option != 0);

		env->terminateConnection(conn);
		Environment::terminateEnvironment(env);
	}
	catch (SQLException& sqlExcp)
	{
		cout << sqlExcp.getErrorCode() << ": " << sqlExcp.getMessage();
	}
	return 0;
}

//returns an integer value which is the selected option by the user from the menu
int mainMenu()
{
	cout << "******************** Main Menu ********************" << endl;
	cout << "1) Login" << endl;
	cout << "0) Exit" << endl;
	cout << "Enter an option (0-1): ";

	int choice;
	char newline;
	bool done;

	//check if the user enters a valid option. Loop until user adds a valid option
	do
	{
		cin >> choice;
		newline = cin.get();
		if (cin.fail() || newline != '\n')
		{
			done = false;
			cin.clear();
			cin.ignore(1000, '\n');
			cout << "You entered a wrong value. Enter an option (0-1): ";
		}
		else
		{
			done = choice >= 0 && choice <= 1;
			if (!done)
			{
				cout << "You entered a wrong value. Enter an option (0-1): ";
			}
		}
	} while (!done);
	return choice;
}

// This function receives an integer value as a customer ID and checks if the customer does exist in the database.
int customerLogin(Connection* conn, int customerId)
{
	int found = 0;
	Statement* stmt = conn->createStatement();
	
	// call the find_customer procedure
	stmt->setSQL("BEGIN"
		" find_customer(:1, :2);"
		" END;"
	);
	stmt->setNumber(1, customerId);
	stmt->registerOutParam(2, Type::OCCIINT, sizeof(found));
	stmt->executeUpdate();
	found = stmt->getInt(2);

	return found;
}

//receives an OCCI pointer (a reference variable to an Oracle database) and an array of type ShoppingCart.
int addToCart(Connection* conn, struct ShoppingCart cart[])
{
	cout << "-------------- Add Products to Cart --------------" << endl;
	for (int i = 0; i < MAX_CART_SIZE; ++i) 
	{
		int productId, qty, choice;
		ShoppingCart item;

		do 
		{
			//prompt the user for product ID
			cout << "Enter the product ID: ";
			cin >> productId;

			// call findProduct to see if the product ID exists
			if (!findProduct(conn, productId)) 
			{
				cout << "The product does not exist. Try again..." << endl;
			}
		} while (!findProduct(conn, productId));

		// displays the product's price
		cout << "Product Price: " << findProduct(conn, productId) << endl;

		// prompt the user to enter the quantity
		cout << "Enter the product Quantity: ";
		cin >> qty;
		item.product_id = productId;
		item.price = findProduct(conn, productId);
		item.quantity = qty;
		cart[i] = item;

		//check if cart is full and return the number of products in the cart
		if (i == MAX_CART_SIZE - 1)
		{
			return i + 1;
		}
		else 
		{
			do 
			{
				cout << "Enter 1 to add more products or 0 to checkout: ";
				cin >> choice;
			} while (choice != 0 && choice != 1);
		}
		if (choice == 0)
			return i + 1;
	}
}

//receives an OCCI pointer (a reference variable to an Oracle database) and an integer value as the product ID.
double findProduct(Connection* conn, int product_id)
{
	Statement* stmt = conn->createStatement();
	// call the find_product stored procedure
	stmt->setSQL("BEGIN"
		" find_product(:1, :2);"
		" END;");
	double price = 0;
	stmt->setNumber(1, product_id);
	stmt->registerOutParam(2, Type::OCCIDOUBLE, sizeof(price));
	stmt->executeUpdate();

	//store the out parameter into price
	price = stmt->getDouble(2);
	conn->terminateStatement(stmt);
	return price;
}

//displays adll the products added to the shopping cart 
void displayProducts(struct ShoppingCart cart[], int productCount)
{
	double total = 0;
	cout << "------- Ordered Products ---------" << endl;
	for (int i = 0; i < productCount; i++)
	{
		cout << "---Item " << i + 1 << endl;
		cout << "Product ID: " << cart[i].product_id << endl;
		cout << "Price: " << cart[i].price << endl;
		cout << "Quantity: " << cart[i].quantity << endl;
		
		//calculating order amount = 'price * quantity' for every item in the cart
		total += cart[i].quantity * cart[i].price;
	}
	cout << "----------------------------------" << endl;
	
	// display the total amount of the order
	cout << "Total: " << total << endl;
}

//this function receives an OCCI pointer(a reference variable to an Oracle database), an array of type ShoppingCart, an integer value as the customer ID, 
//and an integer value as the number of ordered items(products).
int checkout(Connection* conn, struct ShoppingCart cart[], int customerId, int productCount)
{
	int newOrderId = 0;
	char choice;
	char newline;

	do
	{
		//ask user if they want to checkout
		cout << "Would you like to checkout? (Y/y or N/n) ";
		cin >> choice;

		//check if the user entered a valid option
		newline = cin.get();
		if (cin.fail() || newline != '\n')
		{
			cin.clear();
			cin.ignore(1000, '\n');
			cout << "Wrong input. Try again..." << endl;
		}
		else
		{
			if (choice != 'Y' && choice != 'y' && choice != 'N' && choice != 'n')
			{
				cout << "Wrong input. Try again..." << endl;
			}
		}
	} while (choice != 'Y' && choice != 'y' && choice != 'N' && choice != 'n');

	if (choice == 'Y' || choice == 'y')
	{
		Statement* stmt = conn->createStatement();

		// call the add_order stored procedure, that will add a row in the orders table with a new order ID(See the definition of the add_order() procedure.
		stmt->setSQL("BEGIN"
			" add_order(:1, :2);"
			" END;"
		);
		stmt->setNumber(1, customerId);
		stmt->registerOutParam(2, Type::OCCIINT, sizeof(newOrderId));
		stmt->executeUpdate();
		newOrderId = stmt->getInt(2);
		conn->terminateStatement(stmt);
	}
	else
	{
		//terminates and returns 0.
		cout << "The order is cancelled." << endl;
		return 0;
	}

	Statement* stmt = conn->createStatement();

	for (auto i = 0; i < productCount; i++)
	{
		stmt->setSQL("BEGIN"
			" add_order_item(:1, :2, :3, :4, :5);"
			" END;"
		);
		stmt->setNumber(1, newOrderId);
		stmt->setNumber(2, i + 1);
		stmt->setNumber(3, cart[i].product_id);
		stmt->setNumber(4, cart[i].quantity);
		stmt->setDouble(5, cart[i].price);
	}
	conn->terminateStatement(stmt);

	cout << "The order is successfully completed." << endl;
	return 1;
}
