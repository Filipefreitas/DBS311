
#include <iostream>
#include <occi.h>

using oracle::occi::Environment;
using oracle::occi::Connection;
using namespace oracle::occi;
using namespace std;

struct ShoppingCart 
{
	int product_id;
	double price;
	int quantity;
};

//display main menu 
int mainMenu() 
{
	int option = 0;
	do 
	{
		std::cout << "******************** Main Menu ********************\n"
			<< "1) Login\n"
			<< "0) Exit\n";
		if (option != 0 && option != 1) 
		{
			std::cout << "You entered a wrong value. Enter an option (0-1): ";
		}
		else
			std::cout << "Enter an option (0-1): ";
			cin >> option;
	} while (option != 0 && option != 1);
	return option;
}

//receive the product ID and an output parameter named price
double find_product(Connection * conn, int product_id) 
{
	double price;
	Statement* stmt = conn->createStatement();
	stmt->setSQL("BEGIN find_product(:1, :2); END;");
	stmt->setInt(1, product_id); 
	stmt->registerOutParam(2, Type::OCCIDOUBLE, sizeof(price));
	stmt->executeUpdate();
	price = stmt->getDouble(2);
	conn->terminateStatement(stmt);
	return price > 0 ? price : 0;
}
void displayProducts(struct ShoppingCart cart[], int productCount) 
{
	if (productCount > 0) 
	{
		double totalPrice = 0;
		std::cout << "------- Ordered Products ---------" << endl;
		for (int i = 0; i < productCount; ++i) {
			std::cout << "---Item " << i + 1 << endl;
			std::cout << "Product ID: " << cart[i].product_id << endl;
			std::cout << "Price: " << cart[i].price << endl;
			std::cout << "Quantity: " << cart[i].quantity << endl;
			totalPrice += cart[i].price * cart[i].quantity;
		}
		std::cout << "----------------------------------\nTotal: " << totalPrice << endl;
	}
}

int customerLogin(Connection * conn, int customerId) 
{
	Statement* stmt = conn->createStatement();
	stmt->setSQL("BEGIN find_customer(:1, :2); END;");
	int found;
	stmt->setInt(1, customerId);
	stmt->registerOutParam(2, Type::OCCIINT, sizeof(found));
	stmt->executeUpdate();
	found = stmt->getInt(2);
	conn->terminateStatement(stmt);
	return found;
}

int addToCart(Connection * conn, struct ShoppingCart cart[]) 
{
	cout << "-------------- Add Products to Cart --------------" << endl;
	for (int i = 0; i < 5; ++i) {
		int productId;
		int qty;
		ShoppingCart item;
		int choice;
		do 
		{
			cout << "Enter the product ID: ";
			cin >> productId;
			if (find_product(conn, productId) == 0) 
			{
				cout << "The product does not exist. Try again..." << endl;
			}
		} while (find_product(conn, productId) == 0);
		cout << "Product Price: " << find_product(conn, productId) << endl;
		cout << "Enter the product Quantity: ";
		cin >> qty;
		item.product_id = productId;
		item.price = find_product(conn, productId);
		item.quantity = qty;
		cart[i] = item;
		if (i == 4)
			return i + 1;
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

int checkout(Connection* conn, struct ShoppingCart cart[], int customerId, int productCount) 
{
	char choice;
	do 
	{
		cout << "Would you like to checkout? (Y/y or N/n) ";
		cin >> choice;
		if (choice != 'Y' && choice != 'y' && choice != 'N' && choice != 'n')
			cout << "Wrong input. Try again..." << endl;
	} while (choice != 'Y' && choice != 'y' && choice != 'N' && choice != 'n');
	if (choice == 'N' || choice == 'n') 
	{
		cout << "The order is cancelled." << endl;
		return 0;
	}
	else 
	{
		Statement* stmt = conn->createStatement();
		stmt->setSQL("BEGIN add_order(:1, :2); END;");
		int next_order_id;
		stmt->setInt(1, customerId); 
		stmt->registerOutParam(2, Type::OCCIINT, sizeof(next_order_id));
		stmt->executeUpdate();
		next_order_id = stmt->getInt(2);
		for (int i = 0; i < productCount; ++i) 
		{
			stmt->setSQL("BEGIN add_order_item(:1, :2, :3, :4, :5); END; ");
			stmt->setInt(1, next_order_id);
			stmt->setInt(2, i + 1);
			stmt->setInt(3, cart[i].product_id);
			stmt->setInt(4, cart[i].quantity);
			stmt->setDouble(5, cart[i].price);
			stmt->executeUpdate();
		}
		cout << "The order is successfully completed." << endl;
		conn->terminateStatement(stmt);
		return 1;
	}
}

int main() 
{
	Environment* env = nullptr;
	Connection* conn = nullptr;
	string str;
	string user = "dbs311_211f16";
	string pass = "13306282";
	string constr = "myoracle12c.senecacollege.ca:1521/oracle12c";
	try 
	{
		env = Environment::createEnvironment(Environment::DEFAULT);
		conn = env->createConnection(user, pass, constr);
		cout << "Connection is successful!" << endl;
		int choice;
		int customerId;
		do 
		{
			choice = mainMenu();
			if (choice == 1) 
			{
				cout << "Enter the customer ID: ";
				cin >> customerId;
				if (customerLogin(conn, customerId) == 0) 
				{
					cout << "The customer does not exist." << endl;
				}
				else 
				{
					ShoppingCart cart[5];
					int productCnt = addToCart(conn, cart);
					displayProducts(cart, productCnt);
					checkout(conn, cart, customerId, productCnt);
				}

			}
		} while (choice != 0);
		cout << "Good bye!..." << endl;
		env->terminateConnection(conn);
		Environment::terminateEnvironment(env);
	}
	catch (SQLException& sqlExcp) 
	{
		cout << sqlExcp.getErrorCode() << ": " << sqlExcp.getMessage();
	}
	return 0;
}
