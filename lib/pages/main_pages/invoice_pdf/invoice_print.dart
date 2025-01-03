import 'package:app/widgets/custom_text_field.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

class InvoicePrintA4 extends StatefulWidget {
  const InvoicePrintA4({super.key});
  static String id = 'InvoicePrintA4';
  @override
  State<InvoicePrintA4> createState() => _InvoicePrintA4State();
}

class _InvoicePrintA4State extends State<InvoicePrintA4> {
  bool isInsured = true;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(20.sp),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: Colors.black,
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              headerSection(),
              divider(),
              truckDetailsSection(),
              divider(), // reciever section
              recieverSection(),
              divider(),
              senderSection(),
              divider(),
              representativeDetailsSection(),
              divider(),
              shipmentDetailsSection(),
              divider(),
              shipmentCostDetails(),
              divider(),
              notesSection(),
            ],
          ),
        ),
      ),
    );
  }

  SizedBox notesSection() {
    return SizedBox(
      height: 1219.h,
      width: double.infinity,
      child: Image.asset(
        'assets/icons/4-4 Invoice-Print A4.png',
        fit: BoxFit.fill,
      ),
    );
  }

  SizedBox shipmentCostDetails() {
    return SizedBox(
      height: 700.h,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 64.w, vertical: 16.h),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Text(
                  'تفاصيل تكاليف النقل',
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontSize: 60.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 64.h,
            ),
            Expanded(
              child: Row(
                children: [
                  namedTextField("الكلفة الكلية", 'دينار'),
                  SizedBox(
                    width: 64.w,
                  ),
                  namedTextField('كلفة التأمين', 'دينار'),
                  SizedBox(
                    width: 64.w,
                  ),
                  namedTextField('كلفة النقل', 'دينار'),
                  SizedBox(
                    width: 64.w,
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 64.h,
            ),
            Expanded(
              child: Row(
                children: [
                  namedTextField("المبلغ المدفوع", 'دينار'),
                  SizedBox(
                    width: 64.w,
                  ),
                  namedTextField('مصاريف الكمرك', 'دينار'),
                  SizedBox(
                    width: 64.w,
                  ),
                  namedTextField('قيمة الكارتون الفارغ', 'دينار'),
                  SizedBox(
                    width: 64.w,
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 64.h,
            ),
            Expanded(
              child: Row(
                children: [
                  namedTextField("المبلغ المطلوب", 'دينار'),
                  SizedBox(
                    width: 64.w,
                  ),
                  namedTextField('قيمة التخفيض', 'دينار'),
                  SizedBox(
                    width: 64.w,
                  ),
                  namedTextField('كلفةالتوصيل للبيت', 'دينار'),
                  SizedBox(
                    width: 64.w,
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 64.h,
            ),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  namedTextField('المطلوب فى اوروبا', 'EUR'),
                  const Spacer(
                    flex: 2,
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  SizedBox shipmentDetailsSection() {
    return SizedBox(
      height: 600.h,
      child: Padding(
        padding: EdgeInsets.all(
          64.w,
        ),
        child: Column(
          children: [
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        namedTextField('الوزن الكلى', ''),
                        SizedBox(
                          height: 64.h,
                        ),
                        namedTextField('قيمة البضاعة', ''),
                        SizedBox(
                          height: 64.h,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 64.w,
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        namedTextField('عددالقطع', ''),
                        SizedBox(
                          height: 64.h,
                        ),
                        namedTextField('تفاصيل البضاعة', ''),
                        SizedBox(
                          height: 64.h,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 64.w,
                  ),
                  Center(
                    child: Text(
                      'تفاصيل \nالشحنة',
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 60.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Checkbox(
                    value: false,
                    onChanged: (value) {},
                  ),
                  SizedBox(
                    width: 64.w,
                  ),
                  Text(
                    'كلا',
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 40.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(
                    width: 86.w,
                  ),
                  Checkbox(
                    value: false,
                    onChanged: (value) {},
                  ),
                  SizedBox(
                    width: 64.w,
                  ),
                  Text(
                    'نعم',
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 40.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(
                    width: 100.w,
                  ),
                  Text(
                    'تم تأمين البضاعة',
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 40.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Row(
                children: [
                  Expanded(flex: 3, child: namedTextField('الملاحظات', '')),
                  SizedBox(
                    width: 64.w,
                  ),
                  SizedBox(
                    width: 200.w,
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  SizedBox representativeDetailsSection() {
    return SizedBox(
      height: 144.h,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 64.w),
        child: Row(
          children: [
            namedTextField("هاتف الوكيل", ''),
            SizedBox(
              width: 64.w,
            ),
            namedTextField("اسم المكتب", ''),
            SizedBox(
              width: 64.w,
            ),
            namedTextField("اسم الوكيل", ''),
            SizedBox(
              width: 64.w,
            ),
            Text(
              'الوكيل',
              textDirection: TextDirection.rtl,
              style: TextStyle(
                color: Colors.blue,
                fontSize: 60.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  SizedBox senderSection() {
    return SizedBox(
      height: 144.h,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 64.w),
        child: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: CustomTextField(),
                  ),
                  SizedBox(
                    width: 32.w,
                  ),
                  Text(
                    'الهاتف',
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 40.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 64.w,
            ),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: CustomTextField(),
                  ),
                  SizedBox(
                    width: 32.w,
                  ),
                  Text(
                    'الاسم',
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 40.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 64.w,
            ),
            Text(
              'المرسل',
              textDirection: TextDirection.rtl,
              style: TextStyle(
                color: Colors.blue,
                fontSize: 60.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  SizedBox recieverSection() {
    return SizedBox(
      height: 353.h,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 64.w),
        child: Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: CustomTextField(),
                        ),
                        SizedBox(
                          width: 16.w,
                        ),
                        Text(
                          'الهاتف',
                          textDirection: TextDirection.rtl,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 40.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 32.w,
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: CustomTextField(),
                        ),
                        SizedBox(
                          width: 16.w,
                        ),
                        Text(
                          'المدينة',
                          textDirection: TextDirection.rtl,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 40.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 32.w,
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: CustomTextField(),
                        ),
                        SizedBox(
                          width: 16.w,
                        ),
                        Text(
                          'الرقم البريدى',
                          textDirection: TextDirection.rtl,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 40.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 64.w,
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 64.w,
            ),
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: CustomTextField(),
                        ),
                        SizedBox(
                          width: 16.w,
                        ),
                        Text(
                          'الاسم',
                          textDirection: TextDirection.rtl,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 40.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 32.w,
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: CustomTextField(),
                        ),
                        SizedBox(
                          width: 16.w,
                        ),
                        Text(
                          'الدولة',
                          textDirection: TextDirection.rtl,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 40.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 32.w,
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: CustomTextField(),
                        ),
                        SizedBox(
                          width: 16.w,
                        ),
                        Text(
                          'العنوان الكامل',
                          textDirection: TextDirection.rtl,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 40.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 64.w,
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 64.w,
            ),
            Center(
              child: Text(
                'المستلم',
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: 60.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Divider divider() {
    return Divider(
      thickness: 5.sp,
      color: Colors.black,
    );
  }

  SizedBox truckDetailsSection() {
    return SizedBox(
      height: 190.h,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 64.w),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: CustomTextField(),
                  ),
                  SizedBox(
                    width: 16.w,
                  ),
                  Text(
                    'التاريخ',
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 40.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(
                    width: 16.w,
                  ),
                  Icon(
                    Icons.date_range_outlined,
                    size: 40.sp,
                    color: Colors.black,
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 64.w,
            ),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: CustomTextField(),
                  ),
                  SizedBox(
                    width: 16.w,
                  ),
                  Text(
                    'رقم الشحنة',
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 40.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(
                    width: 16.w,
                  ),
                  Icon(
                    Icons.emoji_transportation,
                    size: 40.sp,
                    color: Colors.black,
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 64.w,
            ),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: CustomTextField(),
                  ),
                  SizedBox(
                    width: 16.w,
                  ),
                  Text(
                    'رقم الكود',
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 40.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(
                    width: 16.w,
                  ),
                  Icon(
                    Icons.code,
                    size: 40.sp,
                    color: Colors.black,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  SizedBox headerSection() {
    return SizedBox(
      height: 203.h,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 64.w,
        ),
        child: Row(
          children: [
            SizedBox(
              height: 150.h,
              width: 200.w,
              child: SvgPicture.asset(
                'assets/icons/EUKnet Logo.svg',
              ),
            ),
            SizedBox(
              width: 32.w,
            ),
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  Container(
                    // width: 50,
                    height: 30,
                    margin: const EdgeInsets.only(
                      left: 10,
                      right: 10,
                    ),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xff236bc9),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: 5.0.w,
                        right: 5.w,
                      ),
                      child: AutoSizeText(
                        'EUKnet',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 45.sp,
                          fontStyle: FontStyle.normal,
                        ),
                      ),
                    ),
                  ),
                  AutoSizeText(
                    ' TRANSPORT COMPANY',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 40.sp,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(
              flex: 1,
            ),
            Expanded(
              flex: 2,
              child: AutoSizeText(
                'فرع بغداد - الدورة - قرب كلية دجلة\n 07721001999 - 07702961701',
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontSize: 40.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Spacer(),
            AutoSizeText(
              'شركة ستيرس\n الرائدة فى مجال النقل الدولى',
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontSize: 40.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Expanded namedTextField(String name, String? hint) {
    return Expanded(
      child: Row(
        children: [
          Expanded(
            child: CustomTextField(
              text: hint,
            ),
          ),
          SizedBox(
            width: 32.w,
          ),
          Text(
            name,
            textDirection: TextDirection.rtl,
            style: TextStyle(
              color: Colors.black,
              fontSize: 40.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
