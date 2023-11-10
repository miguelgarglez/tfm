import 'package:combined_playlist_maker/models/user.dart';
import 'package:combined_playlist_maker/services/requests.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

class GetTopItems extends StatefulWidget {
  final String? userId;

  GetTopItems({super.key, this.userId});
  @override
  _GetTopItemsState createState() => _GetTopItemsState();
}

class _GetTopItemsState extends State<GetTopItems> {
  // Variables para los valores del formulario
  String type = 'Tracks';
  double limit = 25;
  String timeRange = 'medium_term';

  // Controladores para los campos de entrada
  final controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Slider buildLimitField() {
    return Slider(
      value: limit,
      onChanged: (newValue) {
        setState(() {
          limit = newValue;
        });
      },
      min: 1.0, // Valor mínimo
      max: 50.0, // Valor máximo
      divisions: 49, // Número de divisiones (de 1 a 50)
      label: limit.round().toString(), // Etiqueta con el valor
    );
  }

  Row buildRadioTopType() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Radio(
          value: 'tracks',
          groupValue: type,
          onChanged: (value) {
            setState(() {
              type = value.toString();
            });
          },
        ),
        Text('Tracks'),
        Radio(
          value: 'artists',
          groupValue: type,
          onChanged: (value) {
            setState(() {
              type = value.toString();
            });
          },
        ),
        Text('Artists'),
      ],
    );
  }

  DropdownButtonFormField buildTimeFrameDropdown() {
    return DropdownButtonFormField(
      value: timeRange,
      items: ['short_term', 'medium_term', 'long_term'].map((time) {
        return DropdownMenuItem(value: time, child: Text(time));
      }).toList(),
      onChanged: (value) {
        setState(() {
          timeRange = value.toString();
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Adjust request parameters'),
      ),
      body: SingleChildScrollView(
        child: Form(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 15, right: 15, top: 15),
                child: Text('Top Tracks or Artists?'),
              ),
              Padding(
                padding: const EdgeInsets.all(15.0),
                child: buildRadioTopType(),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 15, right: 15, top: 15),
                child: Text('What time frame?'),
              ),
              Padding(
                padding: const EdgeInsets.all(15.0),
                child: buildTimeFrameDropdown(),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 15, right: 15, top: 15),
                child: Text('Limit the length of the ranking'),
              ),
              Padding(
                padding: const EdgeInsets.all(15.0),
                child: buildLimitField(),
              ),
              ElevatedButton(
                onPressed: () {
                  print('Va a ejecutar getUsersTopItems!!');
                  getUsersTopItems(widget.userId!, type, timeRange, limit)
                      .then((rankingResponse) {
                    if (rankingResponse.statusCode == 401) {
                      //renovar token
                      var usersBox = Hive.box<User>('users');
                      User? u = usersBox.get(widget.userId);
                      if (u!.updateToken() == true) {
                        context.go(
                            '/users/${widget.userId}/get-recommendations/recommendations',
                            extra: rankingResponse.content);
                      } else {
                        //manejar la falta del token de alguna forma (probablemente)
                        //pidiendo la autorización de nuevo del usuario
                      }
                    } else if (rankingResponse.statusCode != 200) {
                      // mostrar error con un dialog o similar
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text('Error'),
                            content: Text(
                                'Ha ocurrido un error (${rankingResponse.statusCode}) con la API de Spotify. Inténtalo de nuevo'),
                            actions: [
                              TextButton(
                                child: Text('Aceptar'),
                                onPressed: () {
                                  Navigator.of(context)
                                      .pop(); // Cierra el cuadro de diálogo
                                },
                              ),
                            ],
                          );
                        },
                      );
                    } else {
                      context.go(
                          '/users/${widget.userId}/get-top-items/top-items',
                          extra: rankingResponse.content);
                    }
                  });
                },
                child: Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}