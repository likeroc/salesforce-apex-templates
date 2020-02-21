salesforce-apex-templates
=========================

APEX模板提供了一个简单的模板引擎，类似于标准的Salesforce邮件合并引擎。 它的目的是直接从APEX中为提供的SObjects或值映射生成消息和电子邮件。

基本用法
-----------

以下代码段演示了APEX模板的最基本用法：

用法1:
```java
Case someCase = new Case(
  Subject = 'Test Case'
);

// The below will return 'A message for Test Case.'
new Template(
  'A message for {!Case.Subject}.'
).evaluate(someCase);
```

用法2:
```java
Case someCase = new Case(Subject = 'Test Case2333', Description = 'dsc text');
//CaseEmailTemplete is a text email templete,which content is "Subject is {!Case.Subject};Description is : {!Case.Description} ."
//The below wiil return "Subject is Test Case2333;Description is : dsc text ."
String msg = Template.fromEmailTemplate('CaseEmailTemplete').evaluate(someCase);
```
