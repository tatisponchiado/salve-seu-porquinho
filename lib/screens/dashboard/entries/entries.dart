import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:salveSeuPorquinho/components/object_array.dart';
import 'package:salveSeuPorquinho/models/forecast_model.dart';
import 'package:salveSeuPorquinho/models/transac_model.dart';
import 'package:salveSeuPorquinho/models/wrapper_model.dart';
import 'package:salveSeuPorquinho/screens/dashboard/entries/filter_dto.dart';
import 'package:salveSeuPorquinho/screens/dashboard/entries/form_entry.dart';
import 'package:salveSeuPorquinho/services/business/forecast_business.dart';
import 'package:salveSeuPorquinho/services/database/transac_dao.dart';
import 'package:salveSeuPorquinho/services/database/wrapper_dao.dart';
import 'package:salveSeuPorquinho/utils/theme_utils.dart';
import 'package:salveSeuPorquinho/utils/utils.dart';

import 'header.dart';

class EntriesScreen extends StatefulWidget {
  @override
  _EntriesScreenState createState() => _EntriesScreenState();
}

class _EntriesScreenState extends State<EntriesScreen> {
  static const _DELETE_TEXT = "Excluir";

  FilterDto _filter = FilterDto(DateTime.now());
  List<WrapperModel> _wrappers = [];
  List<TransacModel> _transactions = [];

  WrapperDAO wrapperDao = new WrapperDAO();
  TransacDAO transacDao = new TransacDAO();

  @override
  void initState() {
    this.lastDate = null;
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData(_filter);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: <Widget>[
          Header(_filter, _wrappers, (filter) => _loadData(filter)),
          if (_transactions.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                "Nenhum lançamento localizado",
                style: ThemeUtils.bigText,
              ),
            ),
          if (_transactions.isNotEmpty)
            ...ObjectArray(_transactions, _buildTransactionLine).getObjects(),
        ],
      ),
    );
  }

  DateTime lastDate;
  Widget _buildTransactionLine(TransacModel transacion, int index) {
    List<Widget> ws = [];
    if (Utils.dateFormat.format(transacion.date) !=
            Utils.dateFormat.format(lastDate ?? DateTime.now()) ||
        index == 0) {
      ws.add(Padding(
        padding: const EdgeInsets.only(top: 16.0, left: 8),
        child: Text(new DateFormat("EEE - dd/MM").format(transacion.date)),
      ));
      lastDate = transacion.date;
    }

    ws.add(
      Container(
        width: double.maxFinite,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: InkWell(
            onTap: () => _editTransaction(transacion),
            child: Container(
              decoration: BoxDecoration(
                color: Color(0xFF12121A),
                borderRadius: BorderRadius.all(
                  Radius.circular(8),
                ),
              ),
              height: 69,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: <Widget>[
                          Text(transacion.wrapper.name),
                          Text(transacion.descr,
                              style:
                                  ThemeUtils.thinText.copyWith(fontSize: 12)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: <Widget>[
                        Text(
                          "\$ ${Utils.numberFormat.format(transacion.value)}",
                          style:
                              ThemeUtils.strongText.copyWith(color: Colors.red),
                        ),
                        Row(
                          children: <Widget>[
                            Icon(
                              Icons.access_time,
                              size: 16,
                            ),
                            Padding(padding: EdgeInsets.only(left: 4)),
                            Text(Utils.timeFormat.format(transacion.date)),
                          ],
                        ),
                      ],
                    ),
                    InkWell(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: PopupMenuButton<String>(
                          onSelected: (opt) =>
                              _mniMoreOptions(opt, transacion.id),
                          itemBuilder: (BuildContext context) {
                            return [
                              PopupMenuItem<String>(
                                value: "delete",
                                child: Text(_DELETE_TEXT),
                              ),
                            ];
                          },
                        ),
                      ),
                      onTap: () => print('a'),
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: ws,
    );
  }

  _editTransaction(final TransacModel _transaction) async {
    final saved = await Navigator.push(context, MaterialPageRoute(builder: (_) {
          return FormEntry(_transaction, this._wrappers, null);
        })) ??
        false;
    if (saved) await _loadData(_filter);
  }

  _mniMoreOptions(String opt, int transac_id) {
    print(opt + transac_id.toString());
  }

  _loadData(FilterDto _filter) async {
    ForecastModel _forecast =
        await ForecastBusiness.loadIdForecastByDateOrLast(_filter.monthYear);

    List<WrapperModel> _wrappers =
        await wrapperDao.findByForecast(_forecast.id);

    List<TransacModel> _transactions = await transacDao.findByFilter(_filter);

    setState(() {
      this._wrappers = _wrappers;
      this._filter = _filter.copyWith(
        monthYear: DateTime(
          _forecast.year,
          _forecast.month,
          1,
        ),
      );
      this._transactions = _transactions;
    });
  }
}