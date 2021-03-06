import 'package:delivery_app/Services/localStorage.dart';

class DbOperations{

  save(bool isCart, var id){
    String tableName = isCart? 'user_cartItems' : 'user_favItems';
    Map<String,dynamic> data = {
      'iid' : id
    };
    LocalDB.instance.insert(tableName, data);
  }
  getData(bool isCart)async{
    String tableName = isCart? 'user_cartItems' : 'user_favItems';
    List data = await LocalDB.instance.getData(tableName);

    return data;
  }
  delete(bool isCart,var id)async{
    String tableName = isCart? 'user_cartItems' : 'user_favItems';

    LocalDB.instance.delete(tableName, id);
  }
  clearDataBase()async{
    String tableName = 'user_cartItems';

    await LocalDB.instance.clearTable(tableName);
    tableName = 'user_favItems';
    await LocalDB.instance.clearTable(tableName);
    tableName = 'user_homeAddress';
    await LocalDB.instance.clearTable(tableName);
  }
  saveHomeAddress(String address)async{
    String tableName = 'user_homeAddress';

    Map<String,dynamic> data = {
      'Address' : address
    };
    LocalDB.instance.insert(tableName, data);
  }

  getHomeAddress()async{
    String tableName = 'user_homeAddress';

    var res=await LocalDB.instance.getData(tableName);
    if(res.length != 0){
      print(res[0]['Address']);
      return res[0]['Address'];
    }else{
      return '';
    }
  }
  clearHomeAddress()async{
    String tableName = 'user_homeAddress';
    await LocalDB.instance.clearTable(tableName);
  }
}