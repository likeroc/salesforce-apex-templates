/**
 * @author Andrzej Chodor
 */
public class Template {

	//用正则表达式编译为Pattern对象
    private final Pattern MERGE_FIELD_PATTERN = Pattern.compile('\\{!([\\w\\.]+)\\}');

    public final String content;//带有表达式的字符串。如：'A message for {!Case.Subject}. '

    private Object[] lexems;//content子字符串的集合。如：(A message for , Gap:[key=Case.Subject], . )

    public Template(String content) {
        this.content = content;
    }

    /**
     * 把邮件模版的内容存储在全局变量content里
     * @param  developerName String. Email Templete 的 developerName
     * @return               Template
     */
    public static Template fromEmailTemplate(String developerName) {
        EmailTemplate[] emailTpls = [
            SELECT Body, HtmlValue, TemplateType
            FROM EmailTemplate
            WHERE developerName = :developerName
        ];
        if(emailTpls.isEmpty()) {
            throw new TemplateNotFoundException('Template with Unique Name "' + developerName + '" was not found.');
        }
        if(emailTpls[0].TemplateType == 'html' || emailTpls[0].TemplateType == 'custom') {
            return new Template(emailTpls[0].HtmlValue);
        }
        return new Template(emailTpls[0].Body);
    }

    /**
     * 求最终整合后的字符串
     * @param  values     MergeValues，该参数保存了SObject的Name
     * @return            最终整合后的字符串
     */
    public String evaluate(MergeValues values) {
        compile();//编译字符串

        String buffer = '';
        
        for(Object lexem : lexems) {
            Object value = evaluate(lexem, values);
            buffer += format(value);
        }

        return buffer;
    }

    /**
     * 针对只有单个对象表达式的字符串，获取最终整合后的字符串
     * @param  sobjectValue SObject
     * @return              最终整合后的字符串
     */
    public String evaluate(SObject sobjectValue) {
        MergeValues values = new MergeValues();
        values.put(sobjectValue);

        return evaluate(values);
    }

    /**
     * 针对有多个对象表达式的字符串，获取最终整合后的字符串
     * @param  values     [description]
     * @return            String. 最终整合后的字符串
     */
    public String evaluate(Map<String, Object> values) {
        return evaluate(new MergeValues(values));
    }

    public void registerFieldsSecurely(MergeValues values) {
        compile();

        for(Object lexem : lexems) {
            if(lexem instanceof Gap) {
                values.registerFieldSecurely(((Gap)lexem).key);
            }
        }
    }

    private Boolean isCompiled() {
        return lexems != null;
    }

    /**
     * 以表达式为划分点，把content字符串切割成几个小段。
     * 举例：（A message for {!Case.Subject}. ） 切割为(A message for , Gap:[key=Case.Subject], . )
     */
    private void compile() {
        if(isCompiled()) {
            return;
        }
    
        lexems = new List<Object>();

        //创建一个Matcher对象，该对象将输入字符串content与此Pattern对象匹配
        Matcher contentMatcher = MERGE_FIELD_PATTERN.matcher(content);

        Integer processedEnd = 0;
        while(contentMatcher.find()) {//???? 
            if(processedEnd < contentMatcher.start()) {
                lexems.add(content.substring(processedEnd, contentMatcher.start()));
            }

            Gap gapLexem = new Gap(contentMatcher.group(1));//contentMatcher.group(1) = Case.Subject //????
            lexems.add(gapLexem); 
 
            processedEnd = contentMatcher.end(); 
        }

        if(processedEnd < content.length()) {
            lexems.add(content.substring(processedEnd));
        }
    }

    /**
     * lexem如果是字符串，直接返回；如果是Gap数据类型，返回该变量的值
     * @param  lexem      content的一个片段	
     * @param  values     存储了{!}表达式的值
     * @return            表达式的值，或者是Content的一段字符串
     */
    private static Object evaluate(Object lexem, MergeValues values) {
    	
        if(lexem instanceof String) {//判断lexem的数据类型是不是String
            return lexem;
        }

        if(lexem instanceof Gap) {//判断lexem的数据类型是不是Gap对象
            String key = ((Gap)lexem).key;
            try {
                return values.get(key);
            } catch(SObjectException e) {
                return null;
            }
        }
        
        return null;
    }

    /**
     * Object 转化为 String
     * @param  value      Object
     * @return            String
     */
    private static String format(Object value) {
        if(value == null) {
            return '';
        } else if(value instanceof String) {
            return (String)value;
        }

        return String.valueOf(value);
    }

    private class Gap {
        public final String key;

        Gap(String key) {
            this.key = key;
        }
    }

    public class TemplateNotFoundException extends Exception {
    }
}
