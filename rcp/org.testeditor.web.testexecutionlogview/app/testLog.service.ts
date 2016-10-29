import { Injectable } from '@angular/core';
import { Http,  Headers } from '@angular/http';
import 'rxjs/add/operator/toPromise';
import {LogGroup} from "./model";
import {TestExecutionLog, Link} from "./model";

@Injectable()
export class TestLogService {

    constructor(private http: Http) {}

    getTestExecutionLogs(): Promise<TestExecutionLog[]> {
        return this.http.get('http://localhost:19090/services/testexeclogs').toPromise().then(response =>
            response.json().entries as TestExecutionLog[]
        ).catch(this.handleError);
    }

    getTestExecutionLogContent(testExecLog: TestExecutionLog): Promise<String> {
        return this.http.get('http://localhost:19090/services' + testExecLog.links[0].href).toPromise().then(response =>
            response.json().content as String
        ).catch(this.handleError);        
    }

    private handleError(error: any): Promise<any> {
        console.error('An error occurred', error); // for demo purposes only
        return Promise.reject(error.message || error);
    }
}