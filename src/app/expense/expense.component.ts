import { Component, OnInit, Inject } from '@angular/core';
import { Observable } from 'rxjs';
import { Expense } from './../models/expense.model';
import { FormBuilder, FormGroup, Validators, FormControl } from '@angular/forms';
import { UtilityService } from '../services/utility.service';
import { Category } from '../models/category.model';
import { CategoriesService } from '../services/categories.service';
import { ExpensesService } from '../services/expense.service';
import { PaymentMethod } from '../models/payment-method.model';
import { PaymentMethodsService } from './../services/payment-methods.service';
import { MatDialogRef, MAT_DIALOG_DATA } from '@angular/material';

@Component({
  selector: 'app-expense',
  templateUrl: './expense.component.html',
  styleUrls: ['./expense.component.scss']
})
export class ExpenseComponent implements OnInit {

  form: FormGroup;
  submitted: boolean = false;
  success: boolean = false;
  categories: Observable<Category[]>;
  paymentMethods: Observable<PaymentMethod[]>;

  constructor(
    private formBuilder: FormBuilder,
    private util: UtilityService,
    private expensesService: ExpensesService,
    private categoriesService: CategoriesService,
    private paymentMethodsService: PaymentMethodsService,
    public dialogRef: MatDialogRef<ExpenseComponent>,
    @Inject(MAT_DIALOG_DATA) public data: string) {
      this.form = this.createFormGroup();

      if (data != null && data != '') {
        this.expensesService.get(data).subscribe(expense => {
          this.form = this.createFormGroup(expense);
        });
      }
  }

  ngOnInit() {
  }

  ngAfterViewInit() {
    this.categories = this.categoriesService.getAllFromUser();
    this.paymentMethods = this.paymentMethodsService.getAllFromUser();
  }

  createFormGroup(expense?: Expense) {
    var builder = this.formBuilder.group({
      idCategory: new FormControl('', [Validators.required]),
      dateJson: new FormControl(),
      description: new FormControl(),
      id: new FormControl(),
      idPaymentMethod: new FormControl(),
      value: new FormControl()
    });

    if (expense != null) {
      var data: any = expense;
      data.dateJson = this.util.getDateFormat(expense.date);
      builder.patchValue(data);
    }

    return builder;
  }

  onCancelClick() {
    this.dialogRef.close();
  }

  onSubmit() {
    this.submitted = true;

    if (this.form.invalid) {
      return;
    }

    this.saveExpense();
    this.success = true;
  }

  saveExpense() {
    this.util.showLoading();

    var idCategory = this.form.value.idCategory;
    var idPaymentMethod = this.form.value.idPaymentMethod;

    var newExpense = new Expense(
      this.form.value.id,
      this.util.getFullDate(this.form.value.dateJson.toJSON()),
      idCategory,
      this.form.value.description,
      this.form.value.value,
      idPaymentMethod);

    this.expensesService
      .save(newExpense)
      .catch(() => {
        this.util.hideLoading();
      })
      .then(() => {
        this.onCancelClick();
        this.util.hideLoading();   
      })
      .finally(() => {
        this.util.hideLoading();
      });;
  }
}
