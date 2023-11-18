import 'package:combined_playlist_maker/models/user.dart';
import 'package:combined_playlist_maker/return_codes.dart';
import 'package:combined_playlist_maker/services/error_handling.dart';
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
  String type = '';
  double limit = 25;
  String timeRange = 'medium_term';

  final formKey = new GlobalKey<FormState>();

  // Controladores para los campos de entrada
  final controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  bool validateForm() {
    if (type == '') {
      return false;
    } else {
      return true;
    }
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
          key: formKey,
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
                  if (validateForm()) {
                    print('Va a ejecutar getUsersTopItems!!');
                    getUsersTopItems(widget.userId!, type, timeRange, limit)
                        .then((rankingResponse) {
                      if (handleResponse(
                              rankingResponse, widget.userId!, context) ==
                          ReturnCodes.SUCCESS) {
                        context.go(
                            '/users/${widget.userId}/get-top-items/top-items',
                            extra: rankingResponse.content);
                      }
                    });
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Please select "Tracks" or "Artists"',
                        ),
                      ),
                    );
                  }
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
